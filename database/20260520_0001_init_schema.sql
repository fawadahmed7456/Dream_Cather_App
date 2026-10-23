-- Dream Catcher — MVP core schema
-- Project: twbsionwzwwuzldvfdar (Supabase)
-- Tables: users, posts, likes, comments, shares
-- Auth model: Supabase Auth (email-password) is the source of truth.
--             users.id = auth.uid() (Supabase Auth UUID).

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------------
-- Personality type dimensions (Myers-Briggs 16-Personalities)
create type personality_ie as enum ('I', 'E');  -- Introvert / Extrovert
create type personality_sn as enum ('S', 'N');  -- Sensing / Intuition
create type personality_ft as enum ('F', 'T');  -- Feeling / Thinking
create type personality_pj as enum ('P', 'J');  -- Perceiving / Judging

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
create table if not exists public.users (
    id                  uuid        primary key references auth.users(id) on delete cascade,
    username            text        not null unique,
    email               text        not null unique,
    avatar_url          text,
    ethnicity           text,
    gender              text,
    sexual_orientation  text,
    relationship_status text,
    birthday            date,
    -- Personality type (Myers-Briggs dimensions: [I/E, S/N, F/T, P/J])
    personality_ie      personality_ie,
    personality_sn      personality_sn,
    personality_ft      personality_ft,
    personality_pj      personality_pj,
    education_level     text,
    bio                 text,
    phone_number        text,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);

create index if not exists idx_users_email    on public.users (email);
create index if not exists idx_users_username on public.users (lower(username));

-- ---------------------------------------------------------------------------
-- posts
-- ---------------------------------------------------------------------------
create table if not exists public.posts (
    id              uuid        primary key default gen_random_uuid(),
    user_id         uuid        not null references public.users(id) on delete cascade,
    content         text,                           -- text body (nullable for media-only posts)
    media_url       text,                           -- image/video URL from storage
    media_type      text        check (media_type in ('image', 'video')),
    like_count      int         not null default 0,
    comment_count   int         not null default 0,
    share_count     int         not null default 0,
    -- Pre-computed trending score: updated by trigger
    trending_score  float       not null default 0,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    constraint posts_content_check check (content is not null or media_url is not null)
);

create index if not exists idx_posts_user_id        on public.posts (user_id);
create index if not exists idx_posts_created_at      on public.posts (created_at desc);
create index if not exists idx_posts_trending_score  on public.posts (trending_score desc);

-- ---------------------------------------------------------------------------
-- likes
-- ---------------------------------------------------------------------------
create table if not exists public.likes (
    id          uuid        primary key default gen_random_uuid(),
    user_id     uuid        not null references public.users(id) on delete cascade,
    post_id     uuid        not null references public.posts(id) on delete cascade,
    created_at  timestamptz not null default now(),
    unique (user_id, post_id)
);

create index if not exists idx_likes_post_id on public.likes (post_id);
create index if not exists idx_likes_user_id on public.likes (user_id);

-- ---------------------------------------------------------------------------
-- comments
-- ---------------------------------------------------------------------------
create table if not exists public.comments (
    id          uuid        primary key default gen_random_uuid(),
    user_id     uuid        not null references public.users(id) on delete cascade,
    post_id     uuid        not null references public.posts(id) on delete cascade,
    content     text        not null,
    created_at  timestamptz not null default now()
);

create index if not exists idx_comments_post_id     on public.comments (post_id);
create index if not exists idx_comments_created_at  on public.comments (created_at desc);

-- ---------------------------------------------------------------------------
-- shares (track share count)
-- ---------------------------------------------------------------------------
create table if not exists public.shares (
    id          uuid        primary key default gen_random_uuid(),
    user_id     uuid        not null references public.users(id) on delete cascade,
    post_id     uuid        not null references public.posts(id) on delete cascade,
    created_at  timestamptz not null default now()
);

create index if not exists idx_shares_post_id on public.shares (post_id);

-- ---------------------------------------------------------------------------
-- Functions & Triggers
-- ---------------------------------------------------------------------------

-- Like count increment/decrement
create or replace function update_post_like_count()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        update public.posts set like_count = like_count + 1, updated_at = now()
        where id = NEW.post_id;
        return NEW;
    elsif (TG_OP = 'DELETE') then
        update public.posts set like_count = greatest(like_count - 1, 0), updated_at = now()
        where id = OLD.post_id;
        return OLD;
    end if;
    return null;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_like_count on public.likes;
create trigger trg_like_count
    after insert or delete on public.likes
    for each row execute function update_post_like_count();

-- Comment count increment/decrement
create or replace function update_post_comment_count()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        update public.posts set comment_count = comment_count + 1, updated_at = now()
        where id = NEW.post_id;
        return NEW;
    elsif (TG_OP = 'DELETE') then
        update public.posts set comment_count = greatest(comment_count - 1, 0), updated_at = now()
        where id = OLD.post_id;
        return OLD;
    end if;
    return null;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_comment_count on public.comments;
create trigger trg_comment_count
    after insert or delete on public.comments
    for each row execute function update_post_comment_count();

-- Share count increment
create or replace function update_post_share_count()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        update public.posts set share_count = share_count + 1, updated_at = now()
        where id = NEW.post_id;
        return NEW;
    end if;
    return null;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_share_count on public.shares;
create trigger trg_share_count
    after insert on public.shares
    for each row execute function update_post_share_count();

-- Trending score function
create or replace function compute_trending_score(
    p_like_count int,
    p_comment_count int,
    p_share_count int,
    p_created_at timestamptz
) returns float as $$
declare
    raw_score float;
    hours_age float;
begin
    raw_score := (p_like_count * 1.0) + (p_comment_count * 2.0) + (p_share_count * 3.0);
    hours_age := extract(epoch from (now() - p_created_at)) / 3600.0;
    return raw_score / (1.0 + hours_age / 24.0);
end;
$$ language plpgsql immutable;

create or replace function refresh_trending_score()
returns trigger as $$
begin
    update public.posts
    set trending_score = compute_trending_score(like_count, comment_count, share_count, created_at)
    where id = NEW.id;
    return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_trending_score on public.posts;
create trigger trg_trending_score
    after update of like_count, comment_count, share_count on public.posts
    for each row execute function refresh_trending_score();

-- Row Level Security
alter table public.users    enable row level security;
alter table public.posts    enable row level security;
alter table public.likes    enable row level security;
alter table public.comments enable row level security;
alter table public.shares   enable row level security;

commit;
