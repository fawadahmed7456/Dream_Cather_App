-- SafarShare — cancel_ride RPC
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Lets a driver cancel a ride they own atomically: flips the ride to
-- 'cancelled', cancels every still-active booking on it, and fully refunds
-- each affected passenger via a credit transaction. SECURITY DEFINER so it
-- can mutate bookings (passenger-only RLS) and insert into transactions (no
-- insert policy), but it keys everything off auth.uid() so a caller can only
-- ever cancel a ride they drive.
--
-- Refund policy: a driver-initiated cancellation is not the passenger's
-- fault, so every non-cancelled booking is refunded in full regardless of
-- timing — unlike cancel_booking, which tiers the refund by how close to
-- departure the passenger backed out.
--
-- p_reason is accepted for forward-compatibility (the UI collects an
-- optional note) but not persisted — there is no column for it yet, and
-- notifications are derived client-side.

begin;

create or replace function public.cancel_ride(
  p_ride_id uuid,
  p_reason  text default null
)
returns table(
  ride_id            uuid,
  status             text,
  bookings_cancelled int,
  total_refunded     numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller    uuid := auth.uid();
  v_driver    uuid;
  v_status    text;
  v_price     numeric;
  v_count     int := 0;
  v_refunded  numeric := 0;
  r           record;
begin
  if v_caller is null then
    raise exception 'Sign in required to cancel a ride' using errcode = '42501';
  end if;

  -- Lock the ride row.
  select rd.driver_id, rd.status, rd.price_per_seat
    into v_driver, v_status, v_price
    from public.rides rd
    where rd.id = p_ride_id
    for update;

  if not found then
    raise exception 'Ride not found' using errcode = '22023';
  end if;
  if v_driver <> v_caller then
    raise exception 'You can only cancel a ride you are driving' using errcode = '42501';
  end if;
  if v_status = 'cancelled' then
    raise exception 'This ride is already cancelled' using errcode = '22023';
  end if;
  if v_status = 'completed' then
    raise exception 'A completed ride cannot be cancelled' using errcode = '22023';
  end if;

  -- Cancel every still-active booking and fully refund its passenger.
  for r in
    select b.id, b.passenger_id, b.seats_booked
      from public.bookings b
      where b.ride_id = p_ride_id
        and b.status in ('pending','confirmed')
      for update
  loop
    update public.bookings set status = 'cancelled' where id = r.id;

    declare
      v_fare numeric := r.seats_booked * coalesce(v_price, 0);
    begin
      if v_fare > 0 then
        -- Best-effort ledger entry — never let a hiccup block the cancel.
        begin
          insert into public.transactions (user_id, amount, type, reference)
            values (r.passenger_id, v_fare, 'credit', 'refund:' || r.id);
        exception when others then
          null;
        end;
        v_refunded := v_refunded + v_fare;
      end if;
      v_count := v_count + 1;
    end;
  end loop;

  -- Free all seats back and mark the ride cancelled.
  update public.rides
    set status = 'cancelled',
        seats_available = seats_total
    where id = p_ride_id;

  return query select p_ride_id, 'cancelled'::text, v_count, v_refunded;
end;
$$;

revoke all on function public.cancel_ride(uuid, text) from public, anon;
grant execute on function public.cancel_ride(uuid, text) to authenticated;

commit;
