-- Dream Catcher — Row Level Security (RLS) policies
-- Project: twbsionwzwwuzldvfdar (Supabase)
-- Source of Truth: Supabase Auth (auth.uid())

begin;

-- Re-assert RLS defensively
alter table public.users    enable row level security;
alter table public.posts    enable row level security;
alter table public.likes    enable row level security;
alter table public.comments enable row level security;
alter table public.shares   enable row level security;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
-- Anyone authenticated can view user profiles (needed for posts, comments, feeds)
drop policy if exists "users_read_all" on public.users;
create policy "users_read_all"
    on public.users for select
    to authenticated
    using (true);

-- User can create their profile row during onboarding / registration
drop policy if exists "users_insert_self" on public.users;
create policy "users_insert_self"
    on public.users for insert
    to authenticated
    with check (id = auth.uid());

-- User can only update their own profile
drop policy if exists "users_update_self" on public.users;
create policy "users_update_self"
    on public.users for update
    to authenticated
    using (id = auth.uid())
    with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- posts
-- ---------------------------------------------------------------------------
-- All authenticated users can read posts
drop policy if exists "posts_read_all" on public.posts;
create policy "posts_read_all"
    on public.posts for select
    to authenticated
    using (true);

-- User can create posts under their own user_id
drop policy if exists "posts_insert_self" on public.posts;
create policy "posts_insert_self"
    on public.posts for insert
    to authenticated
    with check (user_id = auth.uid());

-- User can update their own posts
drop policy if exists "posts_update_self" on public.posts;
create policy "posts_update_self"
    on public.posts for update
    to authenticated
    using (user_id = auth.uid())
    with check (user_id = auth.uid());

-- User can delete their own posts
drop policy if exists "posts_delete_self" on public.posts;
create policy "posts_delete_self"
    on public.posts for delete
    to authenticated
    using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- likes
-- ---------------------------------------------------------------------------
drop policy if exists "likes_read_all" on public.likes;
create policy "likes_read_all"
    on public.likes for select
    to authenticated
    using (true);

drop policy if exists "likes_insert_self" on public.likes;
create policy "likes_insert_self"
    on public.likes for insert
    to authenticated
    with check (user_id = auth.uid());

drop policy if exists "likes_delete_self" on public.likes;
create policy "likes_delete_self"
    on public.likes for delete
    to authenticated
    using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- comments
-- ---------------------------------------------------------------------------
drop policy if exists "comments_read_all" on public.comments;
create policy "comments_read_all"
    on public.comments for select
    to authenticated
    using (true);

drop policy if exists "comments_insert_self" on public.comments;
create policy "comments_insert_self"
    on public.comments for insert
    to authenticated
    with check (user_id = auth.uid());

drop policy if exists "comments_delete_self" on public.comments;
create policy "comments_delete_self"
    on public.comments for delete
    to authenticated
    using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- shares
-- ---------------------------------------------------------------------------
drop policy if exists "shares_read_all" on public.shares;
create policy "shares_read_all"
    on public.shares for select
    to authenticated
    using (true);

drop policy if exists "shares_insert_self" on public.shares;
create policy "shares_insert_self"
    on public.shares for insert
    to authenticated
    with check (user_id = auth.uid());

commit;
