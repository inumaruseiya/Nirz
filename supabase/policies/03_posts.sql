-- posts RLSポリシー

-- 期限切れでない投稿は全員が閲覧可能
CREATE POLICY "Anyone can view active posts"
ON posts FOR SELECT
USING (expires_at > NOW());

-- ユーザーは投稿を作成可能
CREATE POLICY "Users can create posts"
ON posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ユーザーは自分の投稿のみ削除可能
CREATE POLICY "Users can delete own posts"
ON posts FOR DELETE
USING (auth.uid() = user_id);
