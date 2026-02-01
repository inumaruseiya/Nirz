-- post_images RLSポリシー
CREATE POLICY "Anyone can view post images"
ON post_images FOR SELECT USING (true);

CREATE POLICY "Post owners can add images"
ON post_images FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM posts WHERE id = post_id AND user_id = auth.uid())
);

CREATE POLICY "Post owners can delete images"
ON post_images FOR DELETE USING (
    EXISTS (SELECT 1 FROM posts WHERE id = post_id AND user_id = auth.uid())
);
