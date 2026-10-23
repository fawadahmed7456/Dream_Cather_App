-- SafarShare — Ratings & Reviews system
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Adds a reviews table plus the RPCs the app uses to write and read
-- ratings. A review is one party of a ride rating the other (1–5 stars +
-- optional comment) after the trip has departed. Aggregates into
-- users.rating_avg so the existing driver-rating UI reflects real data.
--
-- Writes go ONLY through submit_review (SECURITY DEFINER): there is no
-- INSERT/UPDATE RLS policy, so a client can't fabricate a rating for a ride
-- they weren't on. Reads of a third party's reviews go through
-- get_user_reviews (SECURITY DEFINER) since the table's own SELECT policy is
-- limited to the reviewer/reviewee.

begin;

create table if not exists public.reviews (
  id           uuid        primary key default gen_random_uuid(),
  ride_id      uuid        not null references public.rides(id) on delete cascade,
  reviewer_id  uuid        not null references public.users(id) on delete cascade,
  reviewee_id  uuid        not null references public.users(id) on delete cascade,
  rating       int         not null check (rating between 1 and 5),
  comment      text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint ux_reviews_ride_pair unique (ride_id, reviewer_id, reviewee_id),
  constraint ck_reviews_not_self  check (reviewer_id <> reviewee_id)
);

create index if not exists idx_reviews_reviewee on public.reviews (reviewee_id);
create index if not exists idx_reviews_ride      on public.reviews (ride_id);

alter table public.reviews enable row level security;

-- A user can read reviews they wrote or received. Browsing another driver's
-- reviews (e.g. on ride details) goes through get_user_reviews instead.
drop policy if exists "reviews_party_select" on public.reviews;
create policy "reviews_party_select"
  on public.reviews for select
  to authenticated
  using (reviewer_id = auth.uid() or reviewee_id = auth.uid());

-- ---------------------------------------------------------------------------
-- submit_review — rate the other party of a ride you were on.
-- ---------------------------------------------------------------------------
create or replace function public.submit_review(
  p_ride_id     uuid,
  p_reviewee_id uuid,
  p_rating      int,
  p_comment     text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller    uuid := auth.uid();
  v_driver    uuid;
  v_departure timestamptz;
  v_status    text;
  v_avg       numeric;
  v_count     int;
  v_id        uuid;
begin
  if v_caller is null then
    raise exception 'Sign in to leave a review' using errcode = '42501';
  end if;
  if p_rating is null or p_rating < 1 or p_rating > 5 then
    raise exception 'Rating must be between 1 and 5' using errcode = '22023';
  end if;
  if p_reviewee_id = v_caller then
    raise exception 'You cannot review yourself' using errcode = '22023';
  end if;

  select rd.driver_id, rd.departure_at, rd.status
    into v_driver, v_departure, v_status
    from public.rides rd
    where rd.id = p_ride_id;
  if not found then
    raise exception 'Ride not found' using errcode = '22023';
  end if;
  -- A cancelled ride never happened, so it can't be rated. (Today this is
  -- also blocked transitively because cancel_ride scrubs every booking, but
  -- guard on the ride status directly so the rule survives future changes.)
  if v_status = 'cancelled' then
    raise exception 'This ride was cancelled' using errcode = '22023';
  end if;
  if v_departure is null or now() < v_departure then
    raise exception 'You can review a ride only after it departs' using errcode = '22023';
  end if;

  -- The caller and reviewee must be the two counterparties of this ride.
  if v_caller = v_driver then
    -- Driver rating a passenger: the reviewee must have travelled.
    if not exists (
      select 1 from public.bookings b
      where b.ride_id = p_ride_id
        and b.passenger_id = p_reviewee_id
        and b.status <> 'cancelled'
    ) then
      raise exception 'That passenger was not on this ride' using errcode = '42501';
    end if;
  else
    -- Passenger rating the driver: the caller must have travelled, and the
    -- reviewee must actually be the driver.
    if p_reviewee_id <> v_driver then
      raise exception 'You can only rate the driver of this ride' using errcode = '42501';
    end if;
    if not exists (
      select 1 from public.bookings b
      where b.ride_id = p_ride_id
        and b.passenger_id = v_caller
        and b.status <> 'cancelled'
    ) then
      raise exception 'You did not travel on this ride' using errcode = '42501';
    end if;
  end if;

  insert into public.reviews (ride_id, reviewer_id, reviewee_id, rating, comment)
    values (p_ride_id, v_caller, p_reviewee_id, p_rating,
            nullif(btrim(coalesce(p_comment, '')), ''))
  on conflict on constraint ux_reviews_ride_pair
    do update set rating = excluded.rating,
                  comment = excluded.comment,
                  updated_at = now()
  returning id into v_id;

  -- Recompute the reviewee's headline rating from all reviews they've received.
  select round(avg(rating)::numeric, 2), count(*)
    into v_avg, v_count
    from public.reviews
    where reviewee_id = p_reviewee_id;

  update public.users set rating_avg = coalesce(v_avg, 0) where id = p_reviewee_id;

  return jsonb_build_object(
    'review_id', v_id,
    'rating_avg', coalesce(v_avg, 0),
    'rating_count', v_count
  );
end;
$$;

revoke all on function public.submit_review(uuid, uuid, int, text) from public, anon;
grant execute on function public.submit_review(uuid, uuid, int, text) to authenticated;

-- ---------------------------------------------------------------------------
-- get_user_reviews — reviews received by a user, with reviewer public info.
-- ---------------------------------------------------------------------------
create or replace function public.get_user_reviews(p_user_id uuid)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'rating', r.rating,
        'comment', r.comment,
        'created_at', r.created_at,
        'reviewer', (
          select to_jsonb(d)
          from (
            select u.id, u.full_name, u.avatar_url
            from public.users u where u.id = r.reviewer_id
          ) d
        )
      )
      order by r.created_at desc
    ),
    '[]'::jsonb
  )
  from public.reviews r
  where r.reviewee_id = p_user_id;
$$;

revoke all on function public.get_user_reviews(uuid) from public, anon;
grant execute on function public.get_user_reviews(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- get_passenger_bookings — now also carries the caller's own review of the
-- ride's driver (my_review), so the My Bookings card can show "Rate driver"
-- vs the rating already left.
-- ---------------------------------------------------------------------------
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
           ),
           'my_review', (
             select to_jsonb(rv)
             from (
               select rev.id, rev.rating, rev.comment
               from public.reviews rev
               where rev.ride_id = b.ride_id
                 and rev.reviewer_id = auth.uid()
                 and rev.reviewee_id = (
                   select rd.driver_id from public.rides rd where rd.id = b.ride_id
                 )
             ) rv
           )
         )
      order by b.created_at desc
    ),
    '[]'::jsonb
  )
  from public.bookings b
  where b.passenger_id = auth.uid();
$$;

-- Re-assert grants on the redefinition (CREATE OR REPLACE preserves existing
-- privileges, but this keeps the migration self-contained and consistent with
-- the other functions above).
revoke all on function public.get_passenger_bookings() from public, anon;
grant execute on function public.get_passenger_bookings() to authenticated;

commit;
