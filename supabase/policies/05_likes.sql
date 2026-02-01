-- likes RLSポリシー

-- 全員がいいねを閲覧可能
CREATE POLICY "Anyone can view likes"
ON likes FOR SELECT
USING (true);

-- ユーザーは自分のいいねのみ管理可能
CREATE POLICY "Users can manage own likes"
ON likes FOR ALL
USING (auth.uid() = user_id);
