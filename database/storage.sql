-- Dream Catcher — Storage buckets + RLS policies
-- Project: twbsionwzwwuzldvfdar (Supabase)
--
-- Buckets:
--   avatars     — user profile avatars (public read, authenticated owner write)
--   posts_media — images/videos attached to social posts (public read, authenticated owner write)

begin;

-- ---------------------------------------------------------------------------
-- 1. Buckets
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    ('avatars', 'avatars', true, 5242880, -- 5MB limit
        array['image/jpeg','image/png','image/webp','image/heic']),
    ('posts_media', 'posts_media', true, 52428800, -- 50MB limit (for images & videos)
        array['image/jpeg','image/png','image/webp','image/heic','video/mp4','video/quicktime'])
on conflict (id) do update
    set public             = excluded.public,
        file_size_limit    = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- 2. Storage Objects RLS Policies
-- ---------------------------------------------------------------------------
drop policy if exists "storage_public_select_avatars" on storage.objects;
create policy "storage_public_select_avatars"
    on storage.objects for select
    using (bucket_id = 'avatars');

drop policy if exists "storage_public_select_posts" on storage.objects;
create policy "storage_public_select_posts"
    on storage.objects for select
    using (bucket_id = 'posts_media');

-- Avatars: authenticated owner-only upload & update
drop policy if exists "storage_avatars_insert_owner" on storage.objects;
create policy "storage_avatars_insert_owner"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'avatars'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "storage_avatars_update_owner" on storage.objects;
create policy "storage_avatars_update_owner"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'avatars'
        and owner = auth.uid()
    )
    with check (
        bucket_id = 'avatars'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "storage_avatars_delete_owner" on storage.objects;
create policy "storage_avatars_delete_owner"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'avatars'
        and owner = auth.uid()
    );

-- Posts Media: authenticated owner-only upload & delete
drop policy if exists "storage_posts_insert_owner" on storage.objects;
create policy "storage_posts_insert_owner"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'posts_media'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "storage_posts_delete_owner" on storage.objects;
create policy "storage_posts_delete_owner"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'posts_media'
        and owner = auth.uid()
    );

commit;
