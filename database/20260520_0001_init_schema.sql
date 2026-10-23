-- SafarShare — MVP core schema
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
-- Tables: users, vehicles, rides, bookings, transactions
-- Auth model: Firebase Auth is the source of truth; users.firebase_uid links the row to the Firebase user.

begin;

-- gen_random_uuid() lives in pgcrypto on older PG, but is built-in on PG 13+ (Supabase).
-- Keep the extension call as a safety net.
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
create table if not exists public.users (
    id            uuid        primary key default gen_random_uuid(),
    firebase_uid  text        not null unique,
    phone         text,
    full_name     text,
    email         text,
    avatar_url    text,
    rating_avg    numeric(3,2) not null default 0.00 check (rating_avg >= 0 and rating_avg <= 5),
    created_at    timestamptz not null default now()
);

create index if not exists idx_users_email on public.users (email);
create index if not exists idx_users_phone on public.users (phone);

-- ---------------------------------------------------------------------------
-- vehicles
-- ---------------------------------------------------------------------------
create table if not exists public.vehicles (
    id            uuid        primary key default gen_random_uuid(),
    owner_id      uuid        not null references public.users(id) on delete cascade,
    make          text        not null,
    model         text        not null,
    year          int         check (year between 1950 and extract(year from now())::int + 1),
    color         text,
    plate_number  text        not null,
    seats         int         not null check (seats between 1 and 20),
    photo_url     text,
    created_at    timestamptz not null default now()
);

create index if not exists idx_vehicles_owner_id     on public.vehicles (owner_id);
create unique index if not exists ux_vehicles_plate  on public.vehicles (lower(plate_number));

-- ---------------------------------------------------------------------------
-- rides
-- ---------------------------------------------------------------------------
create table if not exists public.rides (
    id                uuid        primary key default gen_random_uuid(),
    driver_id         uuid        not null references public.users(id)    on delete restrict,
    vehicle_id        uuid        not null references public.vehicles(id) on delete restrict,
    origin            text        not null,
    destination       text        not null,
    departure_at      timestamptz not null,
    seats_total       int         not null check (seats_total      between 1 and 20),
    seats_available   int         not null check (seats_available >= 0 and seats_available <= seats_total),
    price_per_seat    numeric(10,2) not null check (price_per_seat >= 0),
    status            text        not null default 'active'
                                  check (status in ('active','completed','cancelled')),
    created_at        timestamptz not null default now()
);

-- Search indexes called out in acceptance criteria
create index if not exists idx_rides_origin        on public.rides (origin);
create index if not exists idx_rides_destination   on public.rides (destination);
create index if not exists idx_rides_departure_at  on public.rides (departure_at);
-- Combined index used by the most common search (origin + destination + future departures)
create index if not exists idx_rides_search        on public.rides (origin, destination, departure_at);
create index if not exists idx_rides_driver_id     on public.rides (driver_id);
create index if not exists idx_rides_vehicle_id    on public.rides (vehicle_id);
create index if not exists idx_rides_status        on public.rides (status);

-- ---------------------------------------------------------------------------
-- bookings
-- ---------------------------------------------------------------------------
create table if not exists public.bookings (
    id            uuid        primary key default gen_random_uuid(),
    ride_id       uuid        not null references public.rides(id) on delete cascade,
    passenger_id  uuid        not null references public.users(id) on delete restrict,
    seats_booked  int         not null check (seats_booked >= 1),
    status        text        not null default 'pending'
                              check (status in ('pending','confirmed','cancelled')),
    created_at    timestamptz not null default now()
);

create index if not exists idx_bookings_ride_id       on public.bookings (ride_id);
create index if not exists idx_bookings_passenger_id  on public.bookings (passenger_id);
create index if not exists idx_bookings_status        on public.bookings (status);

-- A passenger should not be able to hold two active bookings on the same ride.
create unique index if not exists ux_bookings_ride_passenger_active
    on public.bookings (ride_id, passenger_id)
    where status in ('pending','confirmed');

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
create table if not exists public.transactions (
    id          uuid        primary key default gen_random_uuid(),
    user_id     uuid        not null references public.users(id) on delete restrict,
    amount      numeric(12,2) not null check (amount >= 0),
    type        text        not null check (type in ('credit','debit')),
    reference   text,
    created_at  timestamptz not null default now()
);

create index if not exists idx_transactions_user_id     on public.transactions (user_id);
create index if not exists idx_transactions_created_at  on public.transactions (created_at desc);
create index if not exists idx_transactions_reference   on public.transactions (reference);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- Enable RLS on every table. Policies are intentionally left out of this
-- migration — they need to be designed against the Firebase-Auth-to-Supabase
-- JWT bridge that the backend will use, and that work is tracked separately.
-- Until policies are added, only the service_role key can read/write.
-- ---------------------------------------------------------------------------
alter table public.users        enable row level security;
alter table public.vehicles     enable row level security;
alter table public.rides        enable row level security;
alter table public.bookings     enable row level security;
alter table public.transactions enable row level security;

commit;
