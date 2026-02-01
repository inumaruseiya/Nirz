-- Storageバケット作成

-- avatarsバケット（プロフィール画像用）
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- post-imagesバケット（投稿画像用）
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-images', 'post-images', true);
