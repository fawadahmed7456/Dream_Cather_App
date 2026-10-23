-- SafarShare — get_ride_detail RPC
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Returns a single ride with its driver + vehicle nested, in the exact
-- shape the ride-details screen expects:
--   { ...ride columns, driver: {...}, vehicle: {...} }
--
-- Why an RPC instead of a PostgREST embed (rides?select=...,driver:users(...)):
-- the users table is locked to `id = auth.uid()` (you can only read your OWN
-- row) and vehicles to `owner_id = auth.uid()`, so a *passenger* viewing a
-- ride got a null driver and null vehicle — there was no driver name, rating,
-- or car on the screen. This SECURITY DEFINER function bypasses those
-- table policies but returns ONLY whitelisted, non-sensitive public columns
-- (no firebase_uid / email), and still enforces who may view the ride:
--   * the ride is active (publicly listed), OR
--   * the caller is the driver, OR
--   * the caller has a booking on the ride.
-- Otherwise it returns null (ride not found / not visible).

begin;

create or replace function public.get_ride_detail(p_ride_id uuid)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select to_jsonb(r)
         || jsonb_build_object(
              'driver', (
                select to_jsonb(d)
                from (
                  select u.id, u.full_name, u.phone, u.avatar_url, u.rating_avg
                  from public.users u
                  where u.id = r.driver_id
                ) d
              ),
              'vehicle', (
                select to_jsonb(v)
                from (
                  select ve.id, ve.make, ve.model, ve.year, ve.color,
                         ve.plate_number, ve.photo_url, ve.seats
                  from public.vehicles ve
                  where ve.id = r.vehicle_id
                ) v
              )
            )
  from public.rides r
  where r.id = p_ride_id
    and (
      r.status = 'active'
      or r.driver_id = auth.uid()
      or exists (
        select 1 from public.bookings b
        where b.ride_id = r.id and b.passenger_id = auth.uid()
      )
    );
$$;

revoke all on function public.get_ride_detail(uuid) from public, anon;
grant execute on function public.get_ride_detail(uuid) to authenticated;

commit;
