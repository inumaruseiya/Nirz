-- comments RLSポリシー
CREATE POLICY "Anyone can view comments"
ON comments FOR SELECT USING (true);

CREATE POLICY "Users can create comments"
ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
ON comments FOR DELETE USING (auth.uid() = user_id);
