-- reports RLSポリシー

-- ユーザーは自分の通報のみ閲覧可能
CREATE POLICY "Users can view own reports"
ON reports FOR SELECT
USING (auth.uid() = reporter_id);

-- ユーザーは通報を作成可能
CREATE POLICY "Users can create reports"
ON reports FOR INSERT
WITH CHECK (auth.uid() = reporter_id);
