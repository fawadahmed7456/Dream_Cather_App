class AppConfig {
  const AppConfig._();

  static const String googleAPIkey = "AIzaSyBXxQdUjqHSOuZnAO95rTMR1PQ1ajDpcgI";
  static const String supabaseUrl = "https://yersmlrpbjpbzkiawjtr.supabase.co";
  // Legacy HS256 anon key (role=anon, ref=yersmlrpbjpbzkiawjtr). The
  // `sb_publishable_*` new-format key was rejected by PostgREST ("Invalid API
  // key"); the legacy JWT key pairs cleanly with the bridge's HS256 session.
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InllcnNtbHJwYmpwYnpraWF3anRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwNzI4NzQsImV4cCI6MjA5MjY0ODg3NH0.RnnoNgGfKF6Ua1_T70ud6gARmDgKLTICZrXrXfF8muQ";

  // ─── Dev-only static auth override ──────────────────────────────────────
  // When both are non-empty the app skips Firebase OTP + the bridge
  // exchange entirely: SupabaseAuthBridge.userId / .accessToken return
  // these values, the splash routes straight into the bottom-nav, and
  // every repository sees the caller as this user.
  //
  // [devSupabaseUserId] must equal a public.users.id (so RLS policies
  // gated on auth.uid() evaluate true for that row's data).
  //
  // [devSupabaseToken] must be a valid Supabase JWT whose `sub` claim
  // matches devSupabaseUserId. Get one from the Supabase dashboard:
  // SQL editor → `select auth.sign_jwt('{"sub":"<user_id>","role":"authenticated"}'::json, 3600);`
  // or any other JWT-minting helper.
  //
  // Leave BOTH empty in production. Empty → the real OTP/bridge flow runs.
  static const String devSupabaseUserId = '';
  static const String devSupabaseToken = '';

  /// Convenience flag — true when both override values are populated.
  static bool get devAuthEnabled =>
      devSupabaseUserId.isNotEmpty && devSupabaseToken.isNotEmpty;

  // ─── Cancel-booking policy ─────────────────────────────────────────────
  // Passenger refund tiers. The frontend uses these to show the user
  // what they'll get back before they confirm; the server-side
  // `cancel_booking` RPC must enforce the same numbers so refunds
  // can't be manipulated client-side.
  //   - Free (100%) when cancelling at least [cancelBookingFreeHours]
  //     before departure.
  //   - Partial ([cancelBookingPartialPercent]%) when cancelling later
  //     than that but still before departure.
  //   - No refund once the ride has departed (UI hides the button).
  static const int cancelBookingFreeHours = 24;
  static const int cancelBookingPartialPercent = 50;

  // ─── Cancel-ride policy ────────────────────────────────────────────────
  // Drivers can only cancel a ride if departure is at least this many
  // hours away. The server enforces this in the `cancel_ride` RPC; the
  // frontend uses the same number to gate the Cancel button so the
  // driver doesn't get an error after tapping. Bump this number if you
  // want stricter notice; lower it (or set to 0) to allow last-minute
  // cancellations.
  static const int cancelRideMinHoursBefore = 2;

  // ─── Support / contact ─────────────────────────────────────────────────
  // Channels surfaced on the Help & Support screen. Replace these
  // placeholders with the real support inbox / number before release.
  //   - [supportPhone]    E.164 with a leading '+', used for the dialer.
  //   - [supportWhatsApp] the same number as bare digits (country code
  //                       first, no '+') for the wa.me deep link.
  static const String supportEmail = 'support@safarshare.pk';
  static const String supportPhone = '+923000000000';
  static const String supportWhatsApp = '923000000000';
  static const String termsUrl = 'https://safarshare.pk/terms';
  static const String privacyUrl = 'https://safarshare.pk/privacy';

  // ─── Sharing / invites ─────────────────────────────────────────────────
  // Link shared from "Share Invitation" on Refer & Earn. This is already
  // the correct Play Store URL for our package id, so it's a real link to
  // share now (it just starts resolving once the app is published) and
  // needs no change at launch.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.safarshare.safar_share';
}
