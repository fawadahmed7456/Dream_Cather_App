-- SafarShare - ride CRUD (update_ride, delete_ride)
-- Drivers already get owner-only INSERT/UPDATE/DELETE via the
-- rides_driver_* RLS policies (driver_id = auth.uid()). These two
-- SECURITY DEFINER RPCs wrap UPDATE/DELETE with the invariants RLS can't
-- express:
--   * update_ride keeps seats_available consistent with already-booked
--     seats and validates the new values (future departure, owned vehicle).
--   * delete_ride refuses to hard-delete a ride that has ANY bookings -
--     bookings.ride_id is ON DELETE CASCADE, so a naive delete would wipe
--     passengers' bookings (and their refunds) silently. Such rides must be
--     cancelled (which refunds passengers) instead.
-- Both are scoped to the caller via auth.uid() so one user can never edit
-- or delete another user's ride.

begin;

create or replace function public.update_ride(
  p_ride_id uuid,
  p_origin text,
  p_destination text,
  p_departure_at timestamptz,
  p_seats_total int,
  p_price_per_seat numeric,
  p_vehicle_id uuid
) returns public.rides
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_ride public.rides;
  v_booked int;
begin
  if v_uid is null then
    raise exception 'Sign in required to edit a ride' using errcode = '42501';
  end if;

  select * into v_ride from public.rides where id = p_ride_id for update;
  if not found then
    raise exception 'Ride not found' using errcode = '22023';
  end if;
  if v_ride.driver_id <> v_uid then
    raise exception 'You can only edit your own ride' using errcode = '42501';
  end if;
  if v_ride.status <> 'active' then
    raise exception 'Only active rides can be edited' using errcode = '22023';
  end if;

  if coalesce(btrim(p_origin), '') = '' or coalesce(btrim(p_destination), '') = '' then
    raise exception 'Origin and destination are required' using errcode = '22023';
  end if;
  if p_departure_at is null or p_departure_at <= now() then
    raise exception 'Departure must be in the future' using errcode = '22023';
  end if;
  if p_price_per_seat is null or p_price_per_seat < 0 then
    raise exception 'Price must be zero or more' using errcode = '22023';
  end if;
  if p_seats_total is null or p_seats_total < 1 then
    raise exception 'At least one seat is required' using errcode = '22023';
  end if;

  -- seats already booked = old total - old available; the new total can't
  -- drop below what's already sold.
  v_booked := v_ride.seats_total - v_ride.seats_available;
  if p_seats_total < v_booked then
    raise exception 'You already have % seat(s) booked on this ride', v_booked
      using errcode = '22023';
  end if;

  if p_vehicle_id is null or not exists (
    select 1 from public.vehicles where id = p_vehicle_id and owner_id = v_uid
  ) then
    raise exception 'Choose one of your own vehicles' using errcode = '22023';
  end if;

  update public.rides set
    origin          = btrim(p_origin),
    destination     = btrim(p_destination),
    departure_at    = p_departure_at,
    seats_total     = p_seats_total,
    seats_available = p_seats_total - v_booked,
    price_per_seat  = p_price_per_seat,
    vehicle_id      = p_vehicle_id
  where id = p_ride_id
  returning * into v_ride;

  return v_ride;
end;
$$;

revoke all on function
  public.update_ride(uuid, text, text, timestamptz, int, numeric, uuid)
  from public, anon;
grant execute on function
  public.update_ride(uuid, text, text, timestamptz, int, numeric, uuid)
  to authenticated;

create or replace function public.delete_ride(p_ride_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_ride public.rides;
begin
  if v_uid is null then
    raise exception 'Sign in required to delete a ride' using errcode = '42501';
  end if;

  select * into v_ride from public.rides where id = p_ride_id for update;
  if not found then
    raise exception 'Ride not found' using errcode = '22023';
  end if;
  if v_ride.driver_id <> v_uid then
    raise exception 'You can only delete your own ride' using errcode = '42501';
  end if;

  -- Any booking row (active or historical) means real passenger/refund data
  -- hangs off this ride; deleting would cascade it away. Make the driver
  -- cancel instead so passengers are refunded and the record is preserved.
  if exists (select 1 from public.bookings where ride_id = p_ride_id) then
    raise exception 'This ride has bookings and cannot be deleted - cancel it instead'
      using errcode = '22023';
  end if;

  delete from public.rides where id = p_ride_id;
  return p_ride_id;
end;
$$;

revoke all on function public.delete_ride(uuid) from public, anon;
grant execute on function public.delete_ride(uuid) to authenticated;

commit;
