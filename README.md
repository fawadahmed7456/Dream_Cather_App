# SafarShare

A carpooling app for Pakistan — drivers post rides, passengers search, book, and split fuel. Built with Flutter (mobile) and Supabase (Postgres + Auth + Storage), with a Firebase OTP → Supabase JWT bridge for authentication.

## Architecture

```
┌────────────────────────┐         ┌──────────────────────────────┐
│  Flutter app (mobile)  │         │  Supabase                    │
│                        │         │  - Postgres (rides, users…)  │
│  Bloc + get_it DI      │ ──────► │  - Row Level Security        │
│  Firebase Auth (OTP)   │         │  - Storage (avatars, photos) │
│  Direct REST + SDK     │         │  - Edge Function: bridge     │
└─────────┬──────────────┘         └────────┬─────────────────────┘
          │                                  │
          │  Firebase ID token               │
          └──────────────► firebase-bridge ──┘
                          (mints Supabase JWT)
```

**Why the bridge?** Supabase Auth doesn't speak Pakistani phone-OTP cheaply. Firebase does. So Firebase handles OTP, then a deno edge function (`supabase/functions/firebase-bridge`) trades the Firebase ID token for a signed Supabase JWT. The Flutter client caches the JWT and attaches it to PostgREST calls so RLS policies (`auth.uid()`) work.

## Repository layout

```
Frontend/                  Flutter app (the mobile client)
  lib/src/
    core/
      config/              Supabase URL, anon key, dev-token override
      di/                  get_it service locator
      services/            SupabaseService, SupabaseAuthBridge, Storage
      routes/              Named routes + page transitions
      utils/               Log helper, Hive storage, validators
    features/
      auth/                Login + OTP screens, AuthCubit
      home/                Stats + recent rides feed
      ride_listing/        Search results + OfferRide form
      ride_details/        Ride detail + booking flow
      bookings/            book_ride RPC client
      profile/             Profile, MyVehicles, EditProfile
      bottom_nav_bar/      App shell + static tab switcher
      splash/              Boot routing (dev-mode vs login)

supabase/
  migrations/              Schema + RLS + storage buckets + book_ride RPC
  functions/firebase-bridge/  Deno edge function (token exchange)
  seeds/dev_seed.sql       Idempotent demo data
```

## Quick start

### Prerequisites

- Flutter SDK 3.27+ (Dart 3.6+)
- Android Studio (for emulator + bundled JDK) **or** Chrome (web build)
- A Supabase project ([supabase.com](https://supabase.com))
- A Firebase project with phone-auth enabled (only needed for real OTP flow)

### 1. Clone

```powershell
git clone https://github.com/<owner>/Safar-Share.git
cd Safar-Share/Frontend
```

### 2. Configure Supabase

Edit `Frontend/lib/src/core/config/app_config.dart`:

```dart
static const String supabaseUrl = "https://<your-project>.supabase.co";
static const String supabaseAnonKey = "<your-anon-key>";
```

### 3. Apply database schema + seed

In the Supabase dashboard → **SQL Editor**, paste and run each file in order:

```
supabase/migrations/20260520000000_init_schema.sql
supabase/migrations/20260520120000_rls_policies.sql
supabase/migrations/20260520130000_storage_buckets.sql
supabase/migrations/20260521000000_book_ride_function.sql
supabase/seeds/dev_seed.sql
```

The seed inserts 3 users, 4 vehicles, 11 rides, and a few confirmed bookings so the home + search screens have something to show.

### 4. Install deps and run

```powershell
flutter pub get
flutter emulators --launch Pixel_Lite   # or any emulator id
flutter run                              # auto-targets the running emulator
```

For web:

```powershell
flutter run -d chrome
```

## Authentication

Two paths are supported.

### Real flow (Firebase OTP → Supabase bridge)

1. Login screen → enter phone → Firebase sends OTP.
2. Verify OTP screen → on success Firebase returns an ID token.
3. App POSTs that token to `/functions/v1/firebase-bridge`.
4. The function verifies the token against Firebase's JWKS and returns a Supabase JWT.
5. `SupabaseAuthBridge` caches the JWT and attaches it as `Authorization: Bearer <jwt>` on every REST call.

Requires deploying the edge function:

```powershell
supabase functions deploy firebase-bridge --no-verify-jwt
```

### Dev bypass (skip OTP, use a static JWT)

Fill both fields in `Frontend/lib/src/core/config/app_config.dart`:

```dart
static const String devSupabaseUserId = '<a public.users.id>';
static const String devSupabaseToken  = '<a JWT signed for that user>';
```

Mint a JWT in Supabase SQL Editor:

```sql
select auth.sign_jwt(
  '{"sub":"<user-id>","role":"authenticated"}'::json,
  604800
);
```

When both are set, the splash skips Login and routes straight to the bottom-nav. Leave them empty in production.

## Data model (high level)

| Table       | Purpose                                          |
|-------------|--------------------------------------------------|
| `users`     | Profile data; `id` matches `auth.users.id`       |
| `vehicles`  | Cars owned by drivers (make/model/plate/photo)   |
| `rides`     | A trip a driver is offering (origin, dest, seats, price) |
| `bookings`  | A passenger's seat reservation on a ride         |

All writes are gated by RLS — users can only update rows they own. The `book_ride(p_ride_id, p_seats)` RPC is `SECURITY DEFINER` and uses `SELECT … FOR UPDATE` to prevent overselling under concurrent bookings.

## State management

- **Bloc** for screens with significant state machines (Home, RideListing, RideDetails, OfferRide, MyVehicles, Profile).
- **Cubit** for simpler flows (AuthCubit).
- Every bloc/cubit extends a `SafeBloc` / `SafeCubit` base that swallows `emit` after close.
- Repositories return `Either<Failure, T>` (dartz) so blocs can `fold` over success/error in one place.
- Cross-cutting services (`SupabaseService`, `SupabaseAuthBridge`, `SupabaseStorageService`, repositories) are resolved via `sl<T>()` from get_it — see `core/di/service_locator.dart`.

## Logging

`Log.{d,i,w,e}('Tag', 'message')` is the only logger used. Every bloc handler, repository call, and bridge step emits structured logs you can grep by tag (`HomeBloc`, `RidesRepo`, `AuthBridge`, etc.).

## Common dev tasks

- **Hot reload after a code edit** — press `r` in the `flutter run` terminal.
- **Hot restart** (e.g. after changing `app_config.dart`) — press `R`.
- **Re-seed the database** — re-run `supabase/seeds/dev_seed.sql` (idempotent).
- **Inspect a query** — Supabase dashboard → SQL Editor.
- **Reset the emulator** — `flutter emulators --launch Pixel_Lite` from a fresh terminal.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `flutter: command not found` | Add `C:\src\flutter\bin` to your user `PATH` and reopen the terminal. |
| `JAVA_HOME is not set` | Set `JAVA_HOME` to `C:\Program Files\Android\Android Studio\jbr`. |
| Gradle: `minSdkVersion 21 cannot be smaller than 23` | Already fixed — `Frontend/android/app/build.gradle` pins `minSdk = 23`. |
| NDK version mismatch | Already fixed — pinned to `27.0.12077973`. |
| Profile screen shows "No profile yet" | You're not signed in. Use the dev token bypass or complete the OTP flow. |
| `intl 0.20 vs 0.19` resolver conflict | Pubspec is pinned to `intl: ^0.19.0` to match the SDK; don't bump it without bumping Flutter. |

## Tech stack

Flutter 3.27 · Dart 3.6 · flutter_bloc 9 · get_it 8 · dartz 0.10 · supabase_flutter 2.8 · firebase_auth 5.4 · hive 2.2 · intl_phone_field 3.2 · logger 2.5

## License

Private — internal SafarShare project.
