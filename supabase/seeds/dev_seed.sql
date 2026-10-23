-- SafarShare — dev seed data
--
-- Run this from the Supabase SQL editor (it bypasses RLS as the
-- dashboard runs as service_role). Idempotent — re-running won't
-- create duplicates.
--
-- After running, three users exist:
--   • Ahmed Raza    (firebase_uid: seed-ahmed) — your "primary" user
--   • Sara Ahmed    (firebase_uid: seed-sara)  — another driver
--   • Umar Farooq   (firebase_uid: seed-umar)  — another driver
--
-- To see Ahmed's data inside the Flutter app, edit Ahmed's
-- firebase_uid to match the uid Firebase Auth gives YOU when you sign
-- in via OTP — uncomment + run the LINKER block at the bottom of this
-- file with your own value plugged in.

begin;

-- ──────────────────────────────────────────────────────────────────
-- 1. Users
-- ──────────────────────────────────────────────────────────────────
insert into public.users (firebase_uid, phone, full_name, email, avatar_url, rating_avg)
values
  ('seed-ahmed', '+92 345 6789012', 'Ahmed Raza',  'ahmed@safar.test', null, 4.7),
  ('seed-sara',  '+92 300 1111111', 'Sara Ahmed',  'sara@safar.test',  null, 4.9),
  ('seed-umar',  '+92 321 2222222', 'Umar Farooq', 'umar@safar.test',  null, 4.6)
on conflict (firebase_uid) do update
  set full_name = excluded.full_name,
      phone     = excluded.phone,
      email     = excluded.email,
      rating_avg = excluded.rating_avg;

-- ──────────────────────────────────────────────────────────────────
-- 2. Vehicles  (idempotent on plate_number)
-- ──────────────────────────────────────────────────────────────────
with
  ahmed as (select id from public.users where firebase_uid = 'seed-ahmed'),
  sara  as (select id from public.users where firebase_uid = 'seed-sara'),
  umar  as (select id from public.users where firebase_uid = 'seed-umar')
insert into public.vehicles (owner_id, make, model, year, color, plate_number, seats)
values
  ((select id from ahmed), 'Toyota',  'Corolla', 2022, 'White',  'ICT-1234', 4),
  ((select id from ahmed), 'Suzuki',  'Cultus',  2020, 'Silver', 'ICT-5678', 4),
  ((select id from sara),  'Honda',   'Civic',   2023, 'Black',  'LEC-7890', 4),
  ((select id from umar),  'Honda',   'City',    2021, 'Grey',   'KHI-4321', 4)
on conflict do nothing;

-- ──────────────────────────────────────────────────────────────────
-- 3. Rides  (idempotent on origin+destination+driver+departure_at)
-- ──────────────────────────────────────────────────────────────────
-- We anchor uniqueness with a partial natural key so re-runs skip.
-- Mix: some completed in the past (stats), some active in the future
-- (search/listing), one active today (recent rides).

with
  ahmed_car as (select id from public.vehicles where plate_number = 'ICT-1234'),
  ahmed_car2 as (select id from public.vehicles where plate_number = 'ICT-5678'),
  sara_car   as (select id from public.vehicles where plate_number = 'LEC-7890'),
  umar_car   as (select id from public.vehicles where plate_number = 'KHI-4321'),
  ahmed as (select id from public.users where firebase_uid = 'seed-ahmed'),
  sara  as (select id from public.users where firebase_uid = 'seed-sara'),
  umar  as (select id from public.users where firebase_uid = 'seed-umar'),

  -- Build the desired rows in a CTE so we can left-join against
  -- existing rides and only insert the missing ones.
  desired (driver_id, vehicle_id, origin, destination, departure_at,
           seats_total, seats_available, price_per_seat, status) as (
    values
      -- Ahmed's completed rides (boost his stats)
      ((select id from ahmed), (select id from ahmed_car),
       'Islamabad', 'Lahore', now() - interval '7 days',
       4, 2, 1500.00, 'completed'),
      ((select id from ahmed), (select id from ahmed_car),
       'Islamabad', 'Rawalpindi', now() - interval '3 days',
       4, 3, 350.00, 'completed'),
      ((select id from ahmed), (select id from ahmed_car2),
       'Lahore', 'Faisalabad', now() - interval '14 days',
       4, 2, 800.00, 'completed'),

      -- Ahmed's upcoming rides (so others can find/book him)
      ((select id from ahmed), (select id from ahmed_car),
       'Islamabad', 'Peshawar', now() + interval '1 day',
       4, 3, 1200.00, 'active'),
      ((select id from ahmed), (select id from ahmed_car),
       'Rawalpindi', 'Murree', now() + interval '3 days',
       4, 4, 500.00, 'active'),

      -- Sara's completed rides (so Ahmed has bookings on them)
      ((select id from sara), (select id from sara_car),
       'Lahore', 'Islamabad', now() - interval '5 days',
       4, 1, 1800.00, 'completed'),
      ((select id from sara), (select id from sara_car),
       'Islamabad', 'Lahore', now() - interval '10 days',
       4, 0, 1700.00, 'completed'),

      -- Sara's active rides (populate the search/listing screen)
      ((select id from sara), (select id from sara_car),
       'Islamabad', 'Lahore', now() + interval '2 days',
       4, 4, 1800.00, 'active'),
      ((select id from sara), (select id from sara_car),
       'Lahore', 'Karachi', now() + interval '5 days',
       4, 4, 4500.00, 'active'),

      -- Umar's active rides
      ((select id from umar), (select id from umar_car),
       'Karachi', 'Hyderabad', now() + interval '1 day',
       4, 4, 600.00, 'active'),
      ((select id from umar), (select id from umar_car),
       'Islamabad', 'Murree', now() + interval '4 days',
       4, 3, 450.00, 'active')
  )
insert into public.rides
  (driver_id, vehicle_id, origin, destination, departure_at,
   seats_total, seats_available, price_per_seat, status)
select d.driver_id, d.vehicle_id, d.origin, d.destination, d.departure_at,
       d.seats_total, d.seats_available, d.price_per_seat, d.status
from desired d
where not exists (
  select 1 from public.rides r
   where r.driver_id    = d.driver_id
     and r.origin       = d.origin
     and r.destination  = d.destination
     and r.departure_at = d.departure_at
);

-- ──────────────────────────────────────────────────────────────────
-- 4. Bookings  (Ahmed booked Sara's completed rides → stats + history)
-- ──────────────────────────────────────────────────────────────────
-- The ux_bookings_ride_passenger_active partial unique index already
-- prevents Ahmed from booking the same ride twice; we use a NOT EXISTS
-- guard so the seed is idempotent.

with
  ahmed as (select id from public.users where firebase_uid = 'seed-ahmed'),
  sara_completed as (
    select r.id
      from public.rides r
      join public.users u on u.id = r.driver_id
     where u.firebase_uid = 'seed-sara'
       and r.status = 'completed'
  )
insert into public.bookings (ride_id, passenger_id, seats_booked, status)
select r.id, (select id from ahmed), 1, 'confirmed'
  from sara_completed r
 where not exists (
   select 1 from public.bookings b
    where b.ride_id = r.id
      and b.passenger_id = (select id from ahmed)
      and b.status in ('pending', 'confirmed')
 );

commit;

-- ──────────────────────────────────────────────────────────────────
-- 5. LINKER (opt-in)  — uncomment + edit, then run as a separate
--     statement to make the Flutter app show Ahmed's seeded data.
--
-- The firebase-bridge edge function looks up public.users by your
-- Firebase uid. Rewire Ahmed to your real Firebase uid so signing in
-- with the app surfaces all the seeded vehicles/rides/bookings.
--
-- To find your Firebase uid: Firebase Console → Authentication →
-- Users → click your row → "User UID".
-- ──────────────────────────────────────────────────────────────────
-- update public.users
--    set firebase_uid = 'PASTE_YOUR_FIREBASE_UID_HERE'
--  where firebase_uid = 'seed-ahmed';
