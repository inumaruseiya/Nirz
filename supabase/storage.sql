-- ============================================
-- Nirz Storage Configuration
-- Supabase Storageバケット・ポリシー定義
-- ============================================

-- ============================================
-- 1. バケット作成
-- ============================================

-- avatarsバケット（プロフィール画像用）
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- post-imagesバケット（投稿画像用）
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-images', 'post-images', true);

-- ============================================
-- 2. Avatars ポリシー
-- ============================================

-- 読み取りは全員可能
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- アップロードは認証済みユーザーのみ（自分のフォルダのみ）
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 削除は自分のもののみ
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================
-- 3. Post Images ポリシー
-- ============================================

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
