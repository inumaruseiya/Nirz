-- blocks RLSポリシー
CREATE POLICY "Users can manage own blocks"
ON blocks FOR ALL USING (auth.uid() = blocker_id);
