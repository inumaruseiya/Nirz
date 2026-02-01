-- profiles RLSポリシー
CREATE POLICY "Anyone can view profiles"
ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can create own profile"
ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE USING (auth.uid() = id);
