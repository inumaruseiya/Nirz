-- user_locations RLSポリシー

-- ユーザーは自分の位置情報のみ閲覧・更新可能
CREATE POLICY "Users can manage own location"
ON user_locations FOR ALL
USING (auth.uid() = user_id);
