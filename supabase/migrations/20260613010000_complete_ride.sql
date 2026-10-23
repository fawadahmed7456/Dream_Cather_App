-- SafarShare — complete_ride RPC
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Lets a driver mark a ride they own as completed once it has actually
-- departed. SECURITY DEFINER so it can update the ride regardless of the
-- caller's role, but keyed on auth.uid() = driver_id so a caller can only
-- ever complete a ride they drive.
--
-- Deliberately does NOT touch bookings or transactions:
--   * bookings.status has no 'completed' state (CHECK allows only
--     pending/confirmed/cancelled), and
--   * the wallet derives a driver's earnings from their rides' *confirmed*
--     bookings (WalletRepository), ignoring the transactions ledger — so
--     flipping bookings away from 'confirmed' would zero out the wallet,
--     and inserting a credit transaction would be invisible to it.
-- Completion is therefore just a status flip plus an earnings summary the
-- UI shows in its success toast (keys: earnings, passengers_completed).

begin;

create or replace function public.complete_ride(p_ride_id uuid)
returns table(
  ride_id              uuid,
  status               text,
  passengers_completed int,
  earnings             numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller     uuid := auth.uid();
  v_driver     uuid;
  v_status     text;
  v_departure  timestamptz;
  v_price      numeric;
  v_seats_sum  int := 0;
  v_count      int := 0;
  v_earnings   numeric := 0;
begin
  if v_caller is null then
    raise exception 'Sign in required to complete a ride' using errcode = '42501';
  end if;

  -- Lock the ride row.
  select rd.driver_id, rd.status, rd.departure_at, rd.price_per_seat
    into v_driver, v_status, v_departure, v_price
    from public.rides rd
    where rd.id = p_ride_id
    for update;

  if not found then
    raise exception 'Ride not found' using errcode = '22023';
  end if;
  if v_driver <> v_caller then
    raise exception 'You can only complete a ride you are driving' using errcode = '42501';
  end if;
  if v_status = 'completed' then
    raise exception 'This ride is already completed' using errcode = '22023';
  end if;
  if v_status = 'cancelled' then
    raise exception 'A cancelled ride cannot be completed' using errcode = '22023';
  end if;
  if v_departure is null or now() < v_departure then
    raise exception 'A ride can only be completed after it departs' using errcode = '22023';
  end if;

  -- Tally the confirmed passengers + earnings for the summary. Bookings are
  -- left 'confirmed' on purpose (see file header).
  select count(*), coalesce(sum(b.seats_booked), 0)
    into v_count, v_seats_sum
    from public.bookings b
    where b.ride_id = p_ride_id
      and b.status = 'confirmed';

  v_earnings := v_seats_sum * coalesce(v_price, 0);

  update public.rides set status = 'completed' where id = p_ride_id;

  return query select p_ride_id, 'completed'::text, v_count, v_earnings;
end;
$$;

revoke all on function public.complete_ride(uuid) from public, anon;
grant execute on function public.complete_ride(uuid) to authenticated;

commit;
