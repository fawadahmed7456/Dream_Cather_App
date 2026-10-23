-- SafarShare — server-side notifications
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Replaces the client-derived notifications feed (built from rides/bookings,
-- with read-state stored locally per device) with a real table:
--   * rows are created server-side by triggers on the events that matter
--     (a new booking, a booking confirmed/cancelled, a ride completed, a
--     review received), so notification logic lives in one place;
--   * `read` lives on the row, so read status syncs across devices;
--   * the app reads its own rows directly via PostgREST (RLS) and marks them
--     read through mark_notifications_read.
--
-- Phase 2 (FCM push) will fan these inserts out to device tokens.

begin;

create table if not exists public.notifications (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  type        text        not null,
  title       text        not null,
  body        text        not null,
  ride_id     uuid        references public.rides(id) on delete set null,
  read        boolean     not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists idx_notifications_user
  on public.notifications (user_id, created_at desc);
create index if not exists idx_notifications_unread
  on public.notifications (user_id) where not read;

alter table public.notifications enable row level security;

-- A user reads only their own notifications. Writes happen via SECURITY
-- DEFINER triggers / the mark-read RPC, so there is no client write policy.
drop policy if exists "notifications_owner_select" on public.notifications;
create policy "notifications_owner_select"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Event triggers — each creates the relevant notification row(s).
-- All SECURITY DEFINER so they can insert regardless of who fired the write.
-- ---------------------------------------------------------------------------

-- New booking -> tell the driver.
create or replace function public.tg_notify_booking_insert()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_driver uuid; v_origin text; v_dest text;
begin
  select r.driver_id, r.origin, r.destination
    into v_driver, v_origin, v_dest
    from public.rides r where r.id = NEW.ride_id;
  if v_driver is not null then
    insert into public.notifications (user_id, type, title, body, ride_id)
      values (v_driver, 'booking_created', 'New booking',
              format('Someone booked %s seat(s) on your ride %s to %s.',
                     NEW.seats_booked, v_origin, v_dest),
              NEW.ride_id);
  end if;
  return NEW;
end $$;

drop trigger if exists trg_booking_insert on public.bookings;
create trigger trg_booking_insert after insert on public.bookings
  for each row execute function public.tg_notify_booking_insert();

-- Booking status change -> tell the passenger.
create or replace function public.tg_notify_booking_update()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_origin text; v_dest text; v_title text; v_body text;
begin
  if NEW.status = OLD.status then return NEW; end if;
  -- Skip when the passenger cancelled their OWN booking: cancel_booking sets
  -- this transaction-local flag before the update, so we don't tell a user
  -- about an action they just performed. cancel_ride (driver-initiated) does
  -- NOT set it, so its passengers are still notified.
  if current_setting('safarshare.suppress_self_notif', true) = 'on' then
    return NEW;
  end if;
  select r.origin, r.destination into v_origin, v_dest
    from public.rides r where r.id = NEW.ride_id;
  if NEW.status = 'confirmed' then
    v_title := 'Booking confirmed';
    v_body  := format('Your seat for %s to %s is confirmed.', v_origin, v_dest);
  elsif NEW.status = 'cancelled' then
    v_title := 'Booking cancelled';
    v_body  := format('Your booking for %s to %s was cancelled.', v_origin, v_dest);
  else
    return NEW;
  end if;
  insert into public.notifications (user_id, type, title, body, ride_id)
    values (NEW.passenger_id, 'booking_' || NEW.status, v_title, v_body, NEW.ride_id);
  return NEW;
end $$;

drop trigger if exists trg_booking_update on public.bookings;
create trigger trg_booking_update after update on public.bookings
  for each row execute function public.tg_notify_booking_update();

-- Ride completed -> tell the driver and every confirmed passenger. (Ride
-- cancellation notifies passengers via the booking-cancel trigger above, so
-- it isn't duplicated here.)
create or replace function public.tg_notify_ride_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if NEW.status = OLD.status then return NEW; end if;
  if NEW.status = 'completed' then
    insert into public.notifications (user_id, type, title, body, ride_id)
      values (NEW.driver_id, 'ride_completed', 'Ride completed',
              format('Your ride %s to %s is complete.', NEW.origin, NEW.destination),
              NEW.id);
    insert into public.notifications (user_id, type, title, body, ride_id)
      select b.passenger_id, 'trip_completed', 'Trip completed',
             format('Hope you enjoyed %s to %s. Leave a rating!',
                    NEW.origin, NEW.destination),
             NEW.id
      from public.bookings b
      where b.ride_id = NEW.id and b.status = 'confirmed';
  end if;
  return NEW;
end $$;

drop trigger if exists trg_ride_update on public.rides;
create trigger trg_ride_update after update on public.rides
  for each row execute function public.tg_notify_ride_update();

-- New review -> tell the person who was rated.
create or replace function public.tg_notify_review_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, type, title, body, ride_id)
    values (NEW.reviewee_id, 'review_received', 'New rating',
            format('You received a %s-star rating.', NEW.rating), NEW.ride_id);
  return NEW;
end $$;

drop trigger if exists trg_review_insert on public.reviews;
create trigger trg_review_insert after insert on public.reviews
  for each row execute function public.tg_notify_review_insert();

-- ---------------------------------------------------------------------------
-- mark_notifications_read — flip read=true for the caller's rows (cross-device).
-- Pass null to mark everything read, or an array of ids for specific ones.
-- ---------------------------------------------------------------------------
create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare v_count int;
begin
  if auth.uid() is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
  if p_ids is null then
    update public.notifications set read = true
      where user_id = auth.uid() and not read;
  else
    update public.notifications set read = true
      where user_id = auth.uid() and id = any(p_ids) and not read;
  end if;
  get diagnostics v_count = row_count;
  return v_count;
end $$;

revoke all on function public.mark_notifications_read(uuid[]) from public, anon;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- Backfill: one "ride published" notification per existing ride so the feed
-- isn't empty for rides created before the triggers existed.
-- ---------------------------------------------------------------------------
insert into public.notifications (user_id, type, title, body, ride_id, created_at)
  select r.driver_id, 'ride_published', 'Ride published',
         format('Your ride %s to %s is live for passengers to book.',
                r.origin, r.destination),
         r.id, r.created_at
  from public.rides r
  where r.status = 'active'
    and not exists (
    select 1 from public.notifications n
    where n.ride_id = r.id and n.type = 'ride_published'
  );

commit;
