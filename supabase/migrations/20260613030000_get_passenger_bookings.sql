-- SafarShare — get_passenger_bookings RPC
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Returns the caller's bookings (newest first) as a jsonb array, each row
-- with its ride and the ride's driver nested, in the exact shape the
-- My Bookings screen reads:
--   [ { ...booking, ride: { ...ride, driver: {...} } }, ... ]
--
-- Why an RPC instead of a PostgREST embed (bookings?select=...,driver:users(...)):
-- the users table is locked to `id = auth.uid()`, so a passenger embedding
-- the ride's `driver:users(...)` got a null driver — the card fell back to a
-- generic "Driver" with no name or rating. This SECURITY DEFINER function
-- bypasses that policy but exposes ONLY whitelisted public driver columns
-- (id, full_name, avatar_url, rating_avg — no phone/email/firebase_uid) and
-- is scoped to the caller's own bookings via auth.uid().

begin;

create or replace function public.get_passenger_bookings()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      to_jsonb(b)
      || jsonb_build_object(
           'ride', (
             select to_jsonb(r)
                    || jsonb_build_object(
                         'driver', (
                           select to_jsonb(d)
                           from (
                             select u.id, u.full_name, u.avatar_url, u.rating_avg
                             from public.users u
                             where u.id = r.driver_id
                           ) d
                         )
                       )
             from public.rides r
             where r.id = b.ride_id
           )
         )
      order by b.created_at desc
    ),
    '[]'::jsonb
  )
  from public.bookings b
  where b.passenger_id = auth.uid();
$$;

revoke all on function public.get_passenger_bookings() from public, anon;
grant execute on function public.get_passenger_bookings() to authenticated;

commit;
