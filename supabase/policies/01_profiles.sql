-- profiles RLSポリシー

-- 全員が全てのプロフィールを閲覧可能
CREATE POLICY "Anyone can view profiles"
ON profiles FOR SELECT
USING (true);

-- ユーザーは自分のプロフィールのみ作成可能
CREATE POLICY "Users can create own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- ユーザーは自分のプロフィールのみ更新可能
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);
