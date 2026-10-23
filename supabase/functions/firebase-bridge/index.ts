/// <reference lib="deno.ns" />

// Supabase Edge Function: firebase-bridge
//
// Exchanges a Firebase ID token for a Supabase JWT.
// Flow:
//   1. Client POSTs { firebase_id_token } after Firebase phone-OTP sign-in.
//   2. We verify the Firebase token (RS256, JWKS from Google).
//   3. Upsert public.users keyed by firebase_uid; capture users.id.
//   4. Mint an HS256 Supabase JWT with sub = users.id, role = authenticated.
//   5. Return { access_token, user_id, expires_in } so the client can call
//      supabase.auth.setSession(access_token).
//
// Env vars required:
//   SUPABASE_URL                — auto-injected by Supabase
//   SUPABASE_SERVICE_ROLE_KEY   — auto-injected by Supabase
//   JWT_SIGNING_SECRET          — set via `supabase secrets set`
//   FIREBASE_PROJECT_ID         — defaults to "safar-share-app-1777089546"

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { jwtVerify, createRemoteJWKSet, SignJWT } from "https://esm.sh/jose@5.9.6";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID") ?? "safar-share-app-1777089546";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const JWT_SECRET = Deno.env.get("JWT_SIGNING_SECRET")!;

const FIREBASE_JWKS = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"),
);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });
}

async function verifyFirebaseIdToken(idToken: string) {
  // Diagnostic: peek at the token to see issuer
  try {
    const parts = idToken.split(".");
    if (parts.length === 3) {
      const payload = JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")), c => c.charCodeAt(0))));
      console.log(`[Bridge Token Info] iss: ${payload.iss}, aud: ${payload.aud}, sub: ${payload.sub}`);
    }
  } catch (e) {
    console.error(`[Bridge Token Peek Failed] ${(e as Error).message}`);
  }

  const expectedIssuer = `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;
  const expectedAudience = FIREBASE_PROJECT_ID;

  // We verify without strict issuer/audience check first to get better error messages
  const { payload } = await jwtVerify(idToken, FIREBASE_JWKS);

  if (payload.iss !== expectedIssuer) {
    throw new Error(`unexpected "iss" claim value. Expected: ${expectedIssuer}, Got: ${payload.iss}`);
  }
  if (payload.aud !== expectedAudience) {
    throw new Error(`unexpected "aud" claim value. Expected: ${expectedAudience}, Got: ${payload.aud}`);
  }

  if (typeof payload.auth_time === "number" && payload.auth_time > Math.floor(Date.now() / 1000)) {
    throw new Error("auth_time is in the future");
  }
  if (!payload.sub) throw new Error("missing sub");

  return payload as {
    sub: string;
    phone_number?: string;
    name?: string;
    email?: string;
    picture?: string;
  };
}

async function upsertUser(claims: { sub: string; phone?: string; name?: string; email?: string; avatar?: string }): Promise<string> {
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // IMPORTANT: do NOT blindly upsert all columns on every login. A Firebase
  // *phone* token carries no name/email/picture, so an unconditional upsert
  // would overwrite the user's app-edited full_name, email and avatar_url
  // with null each time they sign in. Instead: insert on first sign-in,
  // and on return only refresh the phone (the one field the token owns).
  const { data: existing, error: lookupError } = await admin
    .from("users")
    .select("id")
    .eq("firebase_uid", claims.sub)
    .maybeSingle();
  if (lookupError) throw new Error(`lookup failed: ${lookupError.message}`);

  if (existing) {
    if (claims.phone) {
      const { error: updateError } = await admin
        .from("users")
        .update({ phone: claims.phone })
        .eq("id", existing.id);
      if (updateError) throw new Error(`phone update failed: ${updateError.message}`);
    }
    return existing.id;
  }

  // First sign-in: create the profile row from whatever the token provided.
  const { data: created, error: insertError } = await admin
    .from("users")
    .insert({
      firebase_uid: claims.sub,
      phone: claims.phone ?? null,
      full_name: claims.name ?? null,
      email: claims.email ?? null,
      avatar_url: claims.avatar ?? null,
    })
    .select("id")
    .single();

  if (insertError) {
    // Lost a race with a concurrent first sign-in (unique firebase_uid).
    // Re-read instead of failing the login.
    const { data: raced } = await admin
      .from("users")
      .select("id")
      .eq("firebase_uid", claims.sub)
      .maybeSingle();
    if (raced) return raced.id;
    throw new Error(`insert failed: ${insertError.message}`);
  }
  return created.id;
}

async function mintSupabaseJwt(userId: string, claims: { sub: string; phone?: string; name?: string }): Promise<{ token: string; expiresIn: number }> {
  const secret = new TextEncoder().encode(JWT_SECRET);
  const expiresIn = 60 * 60; // 1 hour

  const token = await new SignJWT({
    role: "authenticated",
    app_metadata: { provider: "firebase", providers: ["firebase"] },
    user_metadata: {
      firebase_uid: claims.sub,
      phone: claims.phone ?? null,
      full_name: claims.name ?? null,
    },
  })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .setIssuer("supabase")
    .setAudience("authenticated")
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(`${expiresIn}s`)
    .sign(secret);

  return { token, expiresIn };
}

Deno.serve(async (req) => {
  console.log(`[Bridge Request] ${req.method} ${new URL(req.url).pathname}`);
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let body: { firebase_id_token?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const idToken = body.firebase_id_token;
  if (!idToken || typeof idToken !== "string") {
    return json({ error: "missing_firebase_id_token" }, 400);
  }

  try {
    const verified = await verifyFirebaseIdToken(idToken);
    const claims = {
      sub: verified.sub,
      phone: verified.phone_number,
      name: verified.name,
      email: verified.email,
      avatar: verified.picture,
    };

    const userId = await upsertUser(claims);
    const { token, expiresIn } = await mintSupabaseJwt(userId, claims);

    return json({
      access_token: token,
      token_type: "bearer",
      expires_in: expiresIn,
      user_id: userId,
    });
  } catch (e) {
    const error = e as Error;
    console.error(`[Bridge Error] ${error.stack}`);
    console.log(`[Bridge Debug] Project ID: ${FIREBASE_PROJECT_ID}`);
    const status = error.message.includes("invalid") || error.message.includes("unexpected") || error.message.includes("missing") ? 401 : 500;
    return json({
      error: "invalid_firebase_token",
      detail: error.message,
      stack: error.stack
    }, status);
  }
});
