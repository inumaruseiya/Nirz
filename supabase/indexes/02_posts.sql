-- posts インデックス
CREATE INDEX idx_posts_geography ON posts USING GIST(location);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_expires_at ON posts(expires_at);
CREATE INDEX idx_posts_user_id ON posts(user_id);
