-- DreamCatcher — post_media Storage bucket + RLS policies
-- Bucket: post_media  — public read, authenticated owner-only write
--
-- Conventions
--   Object path MUST be prefixed with the uploader's auth.uid()
--   (e.g. "<uid>/<uuid>.jpg" or "<uid>/<uuid>.mp4"). The INSERT
--   policy enforces this so two authenticated users cannot collide
--   on each other's paths.
--
--   Max file size : 50 MB (50 * 1024 * 1024 = 52_428_800 bytes)
--                   — generous limit to accommodate short video clips.
--   Allowed MIME  : jpeg, png, webp, heic (images)
--                   mp4, quicktime, x-msvideo, x-ms-wmv, webm (videos)

begin;

-- ---------------------------------------------------------------------------
-- 1. Bucket
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'post_media',
    'post_media',
    true,
    52428800,
    array[
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'video/mp4',
        'video/quicktime',
        'video/x-msvideo',
        'video/x-ms-wmv',
        'video/webm'
    ]
)
on conflict (id) do update
    set public             = excluded.public,
        file_size_limit    = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- 2. RLS Policies
-- ---------------------------------------------------------------------------

-- Public SELECT — anyone can read public URLs (bucket public=true also
-- opens /object/public/ routes, but this policy satisfies the SDK list/get).
drop policy if exists "post_media_public_select" on storage.objects;
create policy "post_media_public_select"
    on storage.objects for select
    using (bucket_id = 'post_media');

-- INSERT — authenticated users may only upload into their own folder.
drop policy if exists "post_media_insert_owner" on storage.objects;
create policy "post_media_insert_owner"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'post_media'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- UPDATE — owner only.
drop policy if exists "post_media_update_owner" on storage.objects;
create policy "post_media_update_owner"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'post_media'
        and owner = auth.uid()
    )
    with check (
        bucket_id = 'post_media'
        and owner = auth.uid()
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- DELETE — owner only (used when deleting a post with attached media).
drop policy if exists "post_media_delete_owner" on storage.objects;
create policy "post_media_delete_owner"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'post_media'
        and owner = auth.uid()
    );

commit;
