-- post-images Storageポリシー
CREATE POLICY "Anyone can view post images"
ON storage.objects FOR SELECT USING (bucket_id = 'post-images');

CREATE POLICY "Users can upload post images"
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'post-images'
    AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete own post images"
ON storage.objects FOR DELETE USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
);
