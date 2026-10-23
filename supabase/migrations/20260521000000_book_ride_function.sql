-- SafarShare — book_ride RPC
-- Atomically decrements rides.seats_available and inserts a booking row.
-- Runs as SECURITY DEFINER so it can mutate rides regardless of the
-- driver-only update RLS policy, then internally enforces that the
-- caller is acting as themselves via auth.uid().
--
-- Returns one row: (booking_id, seats_remaining) so the caller can
-- update its local state without a follow-up SELECT.

begin;

create or replace function public.book_ride(p_ride_id uuid, p_seats int)
returns table(booking_id uuid, seats_remaining int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_passenger uuid := auth.uid();
  v_status text;
  v_driver uuid;
  v_seats_available int;
  v_booking_id uuid;
begin
  if v_passenger is null then
    raise exception 'Sign in required to book a ride'
      using errcode = '42501';
  end if;
  if p_seats is null or p_seats < 1 then
    raise exception 'Seats must be at least 1'
      using errcode = '22023';
  end if;

  -- Lock the ride row so two concurrent bookings can't oversell.
  select status, driver_id, seats_available
    into v_status, v_driver, v_seats_available
    from public.rides
    where id = p_ride_id
    for update;

  if not found then
    raise exception 'Ride not found'
      using errcode = '22023';
  end if;
  if v_status <> 'active' then
    raise exception 'Ride is not available for booking'
      using errcode = '22023';
  end if;
  if v_driver = v_passenger then
    raise exception 'You can''t book your own ride'
      using errcode = '22023';
  end if;
  if v_seats_available < p_seats then
    raise exception 'Only % seat(s) left on this ride', v_seats_available
      using errcode = '22023';
  end if;

  update public.rides
    set seats_available = seats_available - p_seats
    where id = p_ride_id;

  -- ux_bookings_ride_passenger_active raises 23505 if the passenger
  -- already has an active booking on this ride; let it propagate so
  -- the seats decrement rolls back with the failed insert.
  insert into public.bookings (ride_id, passenger_id, seats_booked, status)
    values (p_ride_id, v_passenger, p_seats, 'confirmed')
    returning id into v_booking_id;

  return query
    select v_booking_id, v_seats_available - p_seats;
end;
$$;

-- Only authenticated callers (i.e. anyone with a valid JWT) can invoke
-- the function. service_role still works because of its role.
revoke all on function public.book_ride(uuid, int) from public;
grant execute on function public.book_ride(uuid, int) to authenticated;

commit;
