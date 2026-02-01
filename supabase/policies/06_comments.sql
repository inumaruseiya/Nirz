-- comments RLSポリシー

-- 全員がコメントを閲覧可能
CREATE POLICY "Anyone can view comments"
ON comments FOR SELECT
USING (true);

-- ユーザーはコメントを作成可能
CREATE POLICY "Users can create comments"
ON comments FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ユーザーは自分のコメントのみ削除可能
CREATE POLICY "Users can delete own comments"
ON comments FOR DELETE
USING (auth.uid() = user_id);
