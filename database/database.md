# Database

Supabase project: `yersmlrpbjpbzkiawjtr` (region: ap-northeast-1).

## Migrations

| File | Purpose | Applied |
| --- | --- | --- |
| [`20260520_0001_init_schema.sql`](20260520_0001_init_schema.sql) | MVP core schema: `users`, `vehicles`, `rides`, `bookings`, `transactions` (+ FKs, indexes, CHECK constraints, RLS enabled). | 2026-05-20 |
| [`policies.sql`](policies.sql) | RLS policies for all five tables. Locks down anon to public read-only on active rides; gates writes by `auth.uid()`. | 2026-05-20 |
| [`storage.sql`](storage.sql) | Creates `profile_photos` and `vehicle_photos` buckets (5 MB cap, image MIME whitelist) and the storage.objects RLS policies (public read, authenticated owner-only write). | 2026-05-20 |

The Supabase CLI workspace lives at [`../supabase/`](../supabase/). Migration files there mirror the ones in this folder (the CLI requires `YYYYMMDDHHMMSS_*.sql` naming).

## RLS authentication requirement

The policies in `policies.sql` use `auth.uid()`, which returns the Supabase JWT `sub` claim. They evaluate correctly only when `public.users.id` equals the caller's Supabase Auth UUID. Whatever creates the `public.users` row — Supabase Auth signup trigger, or an edge function that mints a Supabase JWT after Firebase verification — must set `users.id = auth.uid()`. A bare Firebase JWT is treated as `anon` and every authenticated policy will deny.

## Applying migrations

```
supabase db push --db-url "postgresql://postgres.yersmlrpbjpbzkiawjtr:<DB_PASS>@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres" --include-all --yes
```

The session pooler is used because the direct host (`db.<ref>.supabase.co`) is IPv6-only.

## Next steps (not in this migration)

- Row Level Security policies — every table has RLS enabled but no policies, so only the `service_role` key can read/write. Policies need to be designed against the Firebase-Auth → Supabase JWT bridge.
- Triggers for `seats_available` decrement on booking confirm.
- Wallet balance materialized view derived from `transactions`.
