-- post_images RLSポリシー

-- 全員が投稿画像を閲覧可能
CREATE POLICY "Anyone can view post images"
ON post_images FOR SELECT
USING (true);

-- 投稿の作成者のみ画像追加可能
CREATE POLICY "Post owners can add images"
ON post_images FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM posts
        WHERE id = post_id AND user_id = auth.uid()
    )
);

-- 投稿の作成者のみ画像削除可能
CREATE POLICY "Post owners can delete images"
ON post_images FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM posts
        WHERE id = post_id AND user_id = auth.uid()
    )
);
