-- blocks RLSポリシー

-- ユーザーは自分のブロックリストのみ管理可能
CREATE POLICY "Users can manage own blocks"
ON blocks FOR ALL
USING (auth.uid() = blocker_id);
