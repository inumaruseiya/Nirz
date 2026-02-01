-- posts RLSポリシー
CREATE POLICY "Anyone can view active posts"
ON posts FOR SELECT USING (expires_at > NOW());

CREATE POLICY "Users can create posts"
ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
ON posts FOR DELETE USING (auth.uid() = user_id);
