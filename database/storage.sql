-- SafarShare — Storage buckets + RLS policies
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- Buckets
--   profile_photos  — public read, authenticated owner-only write
--   vehicle_photos  — public read, authenticated owner-only write
--
-- Conventions
--   Object path MUST be prefixed with the uploader's auth.uid()
--   (e.g. "<uid>/avatar.jpg" or "<uid>/<vehicle_id>.jpg"). The INSERT
--   policies enforce this so two authenticated users cannot collide
--   on each other's paths.
--
--   Max file size: 5 MB (5 * 1024 * 1024 = 5_242_880 bytes).
--   Allowed MIME types: jpeg, png, webp, heic.
--
-- Same identity assumption applies as for the table policies in
-- policies.sql: auth.uid() must match the row in public.users that
-- represents the uploader. See Database/database.md.

begin;

-- ---------------------------------------------------------------------------
-- 1. Buckets
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    ('profile_photos', 'profile_photos', true, 5242880,
        array['image/jpeg','image/png','image/webp','image/heic']),
    ('vehicle_photos', 'vehicle_photos', true, 5242880,
        array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do update
    set public             = excluded.public,
        file_size_limit    = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- 2. RLS on storage.objects is already enabled by Supabase. Define policies.
-- ---------------------------------------------------------------------------

-- Public read of object metadata for these two buckets (the bucket's
-- `public=true` flag already exposes /object/public/ URLs without auth;
-- this SELECT policy lets the SDK list/get objects from anon too).
drop policy if exists "storage_public_select_profile" on storage.objects;
create policy "storage_public_select_profile"
    on storage.objects for select
    using (bucket_id = 'profile_photos');

drop policy if exists "storage_public_select_vehicle" on storage.objects;
create policy "storage_public_select_vehicle"
    on storage.objects for select
    using (bucket_id = 'vehicle_photos');

-- profile_photos: authenticated owner-only INSERT, into their own folder
drop policy if exists "storage_profile_insert_owner" on storage.objects;
create policy "storage_profile_insert_owner"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'profile_photos'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "storage_profile_update_owner" on storage.objects;
create policy "storage_profile_update_owner"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'profile_photos'
        and owner = auth.uid()
    )
    with check (
        bucket_id = 'profile_photos'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "storage_profile_delete_owner" on storage.objects;
create policy "storage_profile_delete_owner"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'profile_photos'
        and owner = auth.uid()
    );

-- vehicle_photos: authenticated owner-only INSERT/UPDATE/DELETE
drop policy if exists "storage_vehicle_insert_owner" on storage.objects;
create policy "storage_vehicle_insert_owner"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'vehicle_photos'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "storage_vehicle_update_owner" on storage.objects;
create policy "storage_vehicle_update_owner"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'vehicle_photos'
        and owner = auth.uid()
    )
    with check (
        bucket_id = 'vehicle_photos'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "storage_vehicle_delete_owner" on storage.objects;
create policy "storage_vehicle_delete_owner"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'vehicle_photos'
        and owner = auth.uid()
    );

commit;
