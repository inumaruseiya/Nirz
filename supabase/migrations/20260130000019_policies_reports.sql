-- reports RLSポリシー
CREATE POLICY "Users can view own reports"
ON reports FOR SELECT USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports"
ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
