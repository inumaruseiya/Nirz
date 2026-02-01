-- user_locations RLSポリシー
CREATE POLICY "Users can manage own location"
ON user_locations FOR ALL USING (auth.uid() = user_id);
