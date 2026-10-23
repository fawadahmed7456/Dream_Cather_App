-- ============================================================================
-- Dream Catcher — Complete Supabase Database Setup
-- Project: twbsionwzwwuzldvfdar
-- Paste and run this script directly in the Supabase Dashboard SQL Editor
-- ============================================================================

begin;

-- Extensions
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 1. Enums (Myers-Briggs 16-Personalities dimensions)
-- ---------------------------------------------------------------------------
do $$
begin
    if not exists (select 1 from pg_type where typname = 'personality_ie') then
        create type personality_ie as enum ('I', 'E');
    end if;
    if not exists (select 1 from pg_type where typname = 'personality_sn') then
        create type personality_sn as enum ('S', 'N');
    end if;
    if not exists (select 1 from pg_type where typname = 'personality_ft') then
        create type personality_ft as enum ('F', 'T');
    end if;
    if not exists (select 1 from pg_type where typname = 'personality_pj') then
        create type personality_pj as enum ('P', 'J');
    end if;
end$$;

-- ---------------------------------------------------------------------------
-- 2. Users Table
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

create index if not exists idx_users_email on public.users (email);
create index if not exists idx_users_username on public.users (lower(username));

-- ---------------------------------------------------------------------------
-- 3. Posts Table
-- ---------------------------------------------------------------------------
create table if not exists public.posts (
    id              uuid        primary key default gen_random_uuid(),
    user_id         uuid        not null references public.users(id) on delete cascade,
    content         text,
    media_url       text,
    media_type      text        check (media_type in ('image', 'video')),
    like_count      int         not null default 0,
    comment_count   int         not null default 0,
    share_count     int         not null default 0,
    trending_score  float       not null default 0,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    constraint posts_content_check check (content is not null or media_url is not null)
);

create index if not exists idx_posts_user_id on public.posts (user_id);
create index if not exists idx_posts_created_at on public.posts (created_at desc);
create index if not exists idx_posts_trending_score on public.posts (trending_score desc);

-- ---------------------------------------------------------------------------
-- 4. Likes Table
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
-- 5. Comments Table
-- ---------------------------------------------------------------------------
create table if not exists public.comments (
    id          uuid        primary key default gen_random_uuid(),
    user_id     uuid        not null references public.users(id) on delete cascade,
    post_id     uuid        not null references public.posts(id) on delete cascade,
    content     text        not null,
    created_at  timestamptz not null default now()
);

create index if not exists idx_comments_post_id on public.comments (post_id);
create index if not exists idx_comments_created_at on public.comments (created_at desc);

-- ---------------------------------------------------------------------------
-- 6. Shares Table
-- ---------------------------------------------------------------------------
create table if not exists public.shares (
    id          uuid        primary key default gen_random_uuid(),
    user_id     uuid        not null references public.users(id) on delete cascade,
    post_id     uuid        not null references public.posts(id) on delete cascade,
    created_at  timestamptz not null default now()
);

create index if not exists idx_shares_post_id on public.shares (post_id);

-- ---------------------------------------------------------------------------
-- 7. Triggers: Counters and Trending Score
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- 8. Row Level Security (RLS)
-- ---------------------------------------------------------------------------
alter table public.users    enable row level security;
alter table public.posts    enable row level security;
alter table public.likes    enable row level security;
alter table public.comments enable row level security;
alter table public.shares   enable row level security;

-- Users policies
drop policy if exists "users_read_all" on public.users;
create policy "users_read_all" on public.users for select to authenticated using (true);

drop policy if exists "users_insert_self" on public.users;
create policy "users_insert_self" on public.users for insert to authenticated with check (id = auth.uid());

drop policy if exists "users_update_self" on public.users;
create policy "users_update_self" on public.users for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Posts policies
drop policy if exists "posts_read_all" on public.posts;
create policy "posts_read_all" on public.posts for select to authenticated using (true);

drop policy if exists "posts_insert_self" on public.posts;
create policy "posts_insert_self" on public.posts for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "posts_update_self" on public.posts;
create policy "posts_update_self" on public.posts for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "posts_delete_self" on public.posts;
create policy "posts_delete_self" on public.posts for delete to authenticated using (user_id = auth.uid());

-- Likes policies
drop policy if exists "likes_read_all" on public.likes;
create policy "likes_read_all" on public.likes for select to authenticated using (true);

drop policy if exists "likes_insert_self" on public.likes;
create policy "likes_insert_self" on public.likes for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "likes_delete_self" on public.likes;
create policy "likes_delete_self" on public.likes for delete to authenticated using (user_id = auth.uid());

-- Comments policies
drop policy if exists "comments_read_all" on public.comments;
create policy "comments_read_all" on public.comments for select to authenticated using (true);

drop policy if exists "comments_insert_self" on public.comments;
create policy "comments_insert_self" on public.comments for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "comments_delete_self" on public.comments;
create policy "comments_delete_self" on public.comments for delete to authenticated using (user_id = auth.uid());

-- Shares policies
drop policy if exists "shares_read_all" on public.shares;
create policy "shares_read_all" on public.shares for select to authenticated using (true);

drop policy if exists "shares_insert_self" on public.shares;
create policy "shares_insert_self" on public.shares for insert to authenticated with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 9. Storage Buckets
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    ('avatars', 'avatars', true, 5242880,
        array['image/jpeg','image/png','image/webp','image/heic']),
    ('posts_media', 'posts_media', true, 52428800,
        array['image/jpeg','image/png','image/webp','image/heic','video/mp4','video/quicktime'])
on conflict (id) do update
    set public             = excluded.public,
        file_size_limit    = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- Storage policies
drop policy if exists "storage_public_select_avatars" on storage.objects;
create policy "storage_public_select_avatars" on storage.objects for select using (bucket_id = 'avatars');

drop policy if exists "storage_public_select_posts" on storage.objects;
create policy "storage_public_select_posts" on storage.objects for select using (bucket_id = 'posts_media');

drop policy if exists "storage_avatars_insert_owner" on storage.objects;
create policy "storage_avatars_insert_owner" on storage.objects for insert to authenticated
    with check (bucket_id = 'avatars' and owner = auth.uid() and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "storage_avatars_update_owner" on storage.objects;
create policy "storage_avatars_update_owner" on storage.objects for update to authenticated
    using (bucket_id = 'avatars' and owner = auth.uid())
    with check (bucket_id = 'avatars' and owner = auth.uid() and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "storage_avatars_delete_owner" on storage.objects;
create policy "storage_avatars_delete_owner" on storage.objects for delete to authenticated
    using (bucket_id = 'avatars' and owner = auth.uid());

drop policy if exists "storage_posts_insert_owner" on storage.objects;
create policy "storage_posts_insert_owner" on storage.objects for insert to authenticated
    with check (bucket_id = 'posts_media' and owner = auth.uid() and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "storage_posts_delete_owner" on storage.objects;
create policy "storage_posts_delete_owner" on storage.objects for delete to authenticated
    using (bucket_id = 'posts_media' and owner = auth.uid());

commit;
