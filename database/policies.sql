-- SafarShare — Row Level Security policies
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- IMPORTANT ASSUMPTION about identity
-- ---------------------------------------------------------------------------
-- These policies use auth.uid(), which returns the `sub` claim of the
-- caller's Supabase JWT. For the policies to evaluate to TRUE for a given
-- user, `public.users.id` MUST equal that user's Supabase Auth UUID (the
-- value of auth.uid()).
--
-- That means whichever flow creates a row in public.users — whether a
-- Supabase Auth signup trigger or an edge function that mints a Supabase
-- JWT after Firebase verification — MUST set public.users.id = auth.uid().
-- If the app continues to rely purely on a Firebase JWT (which Supabase will
-- treat as anon), every policy below will deny access and Realtime/REST
-- calls will return empty results.
--
-- Operations not covered by a policy are denied for both anon and
-- authenticated. The service_role key bypasses RLS entirely, which is how
-- edge functions are expected to insert into transactions.
-- ---------------------------------------------------------------------------

begin;

-- RLS is already enabled by the init migration; re-assert defensively.
alter table public.users        enable row level security;
alter table public.vehicles     enable row level security;
alter table public.rides        enable row level security;
alter table public.bookings     enable row level security;
alter table public.transactions enable row level security;

-- ---------------------------------------------------------------------------
-- users — a user can SELECT/UPDATE only their own row
-- ---------------------------------------------------------------------------
drop policy if exists "users_self_select" on public.users;
create policy "users_self_select"
    on public.users for select
    to authenticated
    using (id = auth.uid());

drop policy if exists "users_self_update" on public.users;
create policy "users_self_update"
    on public.users for update
    to authenticated
    using (id = auth.uid())
    with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- vehicles — owner-only read/write
-- ---------------------------------------------------------------------------
drop policy if exists "vehicles_owner_all" on public.vehicles;
create policy "vehicles_owner_all"
    on public.vehicles for all
    to authenticated
    using (owner_id = auth.uid())
    with check (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- rides — public SELECT on active rides + driver sees their own;
--         driver-only INSERT/UPDATE/DELETE
-- ---------------------------------------------------------------------------
drop policy if exists "rides_public_select" on public.rides;
create policy "rides_public_select"
    on public.rides for select
    using (status = 'active' or driver_id = auth.uid());

drop policy if exists "rides_driver_insert" on public.rides;
create policy "rides_driver_insert"
    on public.rides for insert
    to authenticated
    with check (driver_id = auth.uid());

drop policy if exists "rides_driver_update" on public.rides;
create policy "rides_driver_update"
    on public.rides for update
    to authenticated
    using (driver_id = auth.uid())
    with check (driver_id = auth.uid());

drop policy if exists "rides_driver_delete" on public.rides;
create policy "rides_driver_delete"
    on public.rides for delete
    to authenticated
    using (driver_id = auth.uid());

-- ---------------------------------------------------------------------------
-- bookings — passenger sees own + driver sees bookings on their rides;
--            INSERT restricted to authenticated users acting as themselves
-- ---------------------------------------------------------------------------
drop policy if exists "bookings_self_or_driver_select" on public.bookings;
create policy "bookings_self_or_driver_select"
    on public.bookings for select
    to authenticated
    using (
        passenger_id = auth.uid()
        or exists (
            select 1
            from public.rides r
            where r.id = bookings.ride_id
              and r.driver_id = auth.uid()
        )
    );

drop policy if exists "bookings_passenger_insert" on public.bookings;
create policy "bookings_passenger_insert"
    on public.bookings for insert
    to authenticated
    with check (passenger_id = auth.uid());

-- ---------------------------------------------------------------------------
-- transactions — owner-only SELECT. No INSERT/UPDATE/DELETE policy, so all
-- writes must come from the service_role key (i.e. edge functions).
-- ---------------------------------------------------------------------------
drop policy if exists "transactions_owner_select" on public.transactions;
create policy "transactions_owner_select"
    on public.transactions for select
    to authenticated
    using (user_id = auth.uid());

commit;
