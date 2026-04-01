-- Phase 1-5: Storage (implementation plan 1-5-1 through 1-5-3)
-- Bucket: post-images (public URLs; NFR-SEC-03 via path + owner policies)
-- Client should upload as: {auth.uid()}/{filename}

INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES (
  'post-images',
  'post-images',
  true,
  5242880 -- 5 MiB (1-5-3)
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  name = EXCLUDED.name;

-- -----------------------------------------------------------------------------
-- 1-5-2: Upload — authenticated; path first folder must be auth.uid()
-- -----------------------------------------------------------------------------
CREATE POLICY post_images_insert_authenticated_own_folder
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Public bucket: anon + authenticated can read (feed thumbnails without signed URL)
CREATE POLICY post_images_select_anon_authenticated
  ON storage.objects
  FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'post-images');

-- Overwrite / upsert of own objects
CREATE POLICY post_images_update_own
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'post-images'
    AND owner = auth.uid()
  )
  WITH CHECK (
    bucket_id = 'post-images'
    AND owner = auth.uid()
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Delete — owner only (1-5-2)
CREATE POLICY post_images_delete_own
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'post-images'
    AND owner = auth.uid()
  );
