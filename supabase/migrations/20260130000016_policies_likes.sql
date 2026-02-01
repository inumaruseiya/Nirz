-- likes RLSポリシー
CREATE POLICY "Anyone can view likes"
ON likes FOR SELECT USING (true);

CREATE POLICY "Users can manage own likes"
ON likes FOR ALL USING (auth.uid() = user_id);
