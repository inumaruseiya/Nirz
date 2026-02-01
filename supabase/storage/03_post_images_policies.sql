-- post-images Storageポリシー

-- 読み取りは全員可能
CREATE POLICY "Anyone can view post images"
ON storage.objects FOR SELECT
USING (bucket_id = 'post-images');

-- アップロードは認証済みユーザーのみ
CREATE POLICY "Users can upload post images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'post-images'
    AND auth.role() = 'authenticated'
);

-- 削除は自分のもののみ
CREATE POLICY "Users can delete own post images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
);
