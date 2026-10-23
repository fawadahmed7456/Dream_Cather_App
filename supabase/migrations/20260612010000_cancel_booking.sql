-- SafarShare — cancel_booking RPC
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Lets a passenger cancel their own booking atomically: flips the booking
-- to 'cancelled', restores the ride's seats_available, and records a refund
-- transaction sized per the cancellation policy. SECURITY DEFINER so it can
-- mutate rides (driver-only RLS) and insert into transactions (no insert
-- policy), but it keys everything off auth.uid() so a caller can only ever
-- cancel a booking they own.
--
-- Refund tiers mirror AppConfig.cancelBookingFreeHours / PartialPercent:
--   * > 24h before departure : full refund
--   * < 24h before departure : 50% refund
--   * after departure        : no refund

begin;

create or replace function public.cancel_booking(p_booking_id uuid)
returns table(booking_id uuid, status text, refund_amount numeric)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller     uuid := auth.uid();
  v_passenger  uuid;
  v_ride_id    uuid;
  v_seats      int;
  v_status     text;
  v_departure  timestamptz;
  v_price      numeric;
  v_fare       numeric;
  v_refund     numeric := 0;
  v_free_hours constant int := 24;
  v_partial    constant int := 50;
begin
  if v_caller is null then
    raise exception 'Sign in required to cancel a booking' using errcode = '42501';
  end if;

  -- Lock the booking row.
  select b.passenger_id, b.ride_id, b.seats_booked, b.status
    into v_passenger, v_ride_id, v_seats, v_status
    from public.bookings b
    where b.id = p_booking_id
    for update;

  if not found then
    raise exception 'Booking not found' using errcode = '22023';
  end if;
  if v_passenger <> v_caller then
    raise exception 'You can only cancel your own booking' using errcode = '42501';
  end if;
  if v_status = 'cancelled' then
    raise exception 'This booking is already cancelled' using errcode = '22023';
  end if;
  if v_status = 'completed' then
    raise exception 'A completed booking cannot be cancelled' using errcode = '22023';
  end if;

  select r.departure_at, r.price_per_seat
    into v_departure, v_price
    from public.rides r
    where r.id = v_ride_id
    for update;

  v_fare := v_seats * coalesce(v_price, 0);

  if v_departure is null or now() >= v_departure then
    v_refund := 0;
  elsif now() < v_departure - make_interval(hours => v_free_hours) then
    v_refund := v_fare;
  else
    v_refund := round(v_fare * v_partial / 100.0, 2);
  end if;

  -- Tell the booking-update notification trigger to stay silent: the
  -- passenger is cancelling their own booking, so a "your booking was
  -- cancelled" notification would just echo an action they just took. The
  -- flag is transaction-local; driver-initiated cancels (cancel_ride) don't
  -- set it, so those passengers are still notified.
  perform set_config('safarshare.suppress_self_notif', 'on', true);

  update public.bookings set status = 'cancelled' where id = p_booking_id;

  -- Restore the held seats, capped at the ride's total (satisfies the
  -- seats_available <= seats_total CHECK constraint).
  update public.rides
    set seats_available = least(seats_total, seats_available + v_seats)
    where id = v_ride_id;

  -- Record the refund as a credit. Best-effort — never let a ledger hiccup
  -- block the cancellation itself.
  if v_refund > 0 then
    begin
      insert into public.transactions (user_id, amount, type, reference)
        values (v_caller, v_refund, 'credit', 'refund:' || p_booking_id);
    exception when others then
      null;
    end;
  end if;

  return query select p_booking_id, 'cancelled'::text, v_refund;
end;
$$;

revoke all on function public.cancel_booking(uuid) from public, anon;
grant execute on function public.cancel_booking(uuid) to authenticated;

commit;
