-- ============================================
-- Nirz Row Level Security (RLS) Policies
-- 全テーブルのアクセス制御ポリシー定義
-- ============================================

-- ============================================
-- 1. RLS有効化
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. Profiles ポリシー
-- ============================================

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

-- ============================================
-- 3. User Locations ポリシー
-- ============================================

-- ユーザーは自分の位置情報のみ閲覧・更新可能
CREATE POLICY "Users can manage own location"
ON user_locations FOR ALL
USING (auth.uid() = user_id);

-- ============================================
-- 4. Posts ポリシー
-- ============================================

-- 期限切れでない投稿は全員が閲覧可能
CREATE POLICY "Anyone can view active posts"
ON posts FOR SELECT
USING (expires_at > NOW());

-- ユーザーは投稿を作成可能
CREATE POLICY "Users can create posts"
ON posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ユーザーは自分の投稿のみ削除可能
CREATE POLICY "Users can delete own posts"
ON posts FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- 5. Post Images ポリシー
-- ============================================

-- 全員が投稿画像を閲覧可能
CREATE POLICY "Anyone can view post images"
ON post_images FOR SELECT
USING (true);

-- 投稿の作成者のみ画像追加可能
CREATE POLICY "Post owners can add images"
ON post_images FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM posts
        WHERE id = post_id AND user_id = auth.uid()
    )
);

-- 投稿の作成者のみ画像削除可能
CREATE POLICY "Post owners can delete images"
ON post_images FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM posts
        WHERE id = post_id AND user_id = auth.uid()
    )
);

-- ============================================
-- 6. Likes ポリシー
-- ============================================

-- 全員がいいねを閲覧可能
CREATE POLICY "Anyone can view likes"
ON likes FOR SELECT
USING (true);

-- ユーザーは自分のいいねのみ管理可能
CREATE POLICY "Users can manage own likes"
ON likes FOR ALL
USING (auth.uid() = user_id);

-- ============================================
-- 7. Comments ポリシー
-- ============================================

-- 全員がコメントを閲覧可能
CREATE POLICY "Anyone can view comments"
ON comments FOR SELECT
USING (true);

-- ユーザーはコメントを作成可能
CREATE POLICY "Users can create comments"
ON comments FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ユーザーは自分のコメントのみ削除可能
CREATE POLICY "Users can delete own comments"
ON comments FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- 8. Blocks ポリシー
-- ============================================

-- ユーザーは自分のブロックリストのみ管理可能
CREATE POLICY "Users can manage own blocks"
ON blocks FOR ALL
USING (auth.uid() = blocker_id);

-- ============================================
-- 9. Reports ポリシー
-- ============================================

-- ユーザーは自分の通報のみ閲覧可能
CREATE POLICY "Users can view own reports"
ON reports FOR SELECT
USING (auth.uid() = reporter_id);

-- ユーザーは通報を作成可能
CREATE POLICY "Users can create reports"
ON reports FOR INSERT
WITH CHECK (auth.uid() = reporter_id);
