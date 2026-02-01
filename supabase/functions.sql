-- ============================================
-- Nirz Custom Functions & Triggers
-- カスタム関数・トリガー定義
-- ============================================

-- ============================================
-- 1. 市区町村判定関数
-- 都市コードから表示範囲（1km or 5km）を決定
-- ============================================

CREATE OR REPLACE FUNCTION get_radius_for_city(city_code VARCHAR)
RETURNS INT AS $$
BEGIN
    -- 東京都全域（13xxx）
    IF city_code LIKE '13%' THEN
        RETURN 1;
    END IF;

    -- 大阪府全域（27xxx）
    IF city_code LIKE '27%' THEN
        RETURN 1;
    END IF;

    -- 政令指定都市
    -- 横浜市、川崎市、名古屋市、福岡市、札幌市、仙台市、静岡市、浜松市
    -- 京都市、神戸市、岡山市、広島市、熊本市
    IF city_code IN (
        '14100', '14130', '23100', '40130', '01100',
        '04100', '22100', '22130', '26100', '28100',
        '33100', '34100', '43100'
    ) THEN
        RETURN 1;
    END IF;

    -- その他の地域
    RETURN 5;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 2. タイムライン取得関数
-- 指定位置から範囲内の投稿を取得（ブロック・期限切れ除外）
-- ============================================

CREATE OR REPLACE FUNCTION get_nearby_posts(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    user_radius_km INT,
    page_limit INT DEFAULT 20,
    page_offset INT DEFAULT 0
)
RETURNS TABLE (
    post_id UUID,
    user_id UUID,
    nickname VARCHAR,
    avatar_url TEXT,
    content TEXT,
    images JSONB,
    distance_range TEXT,
    like_count INT,
    comment_count INT,
    is_liked BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_location GEOGRAPHY;
    radius_meters INT;
BEGIN
    user_location := ST_MakePoint(user_lng, user_lat)::geography;
    radius_meters := user_radius_km * 1000;

    RETURN QUERY
    SELECT
        p.id,
        p.user_id,
        prof.nickname,
        prof.avatar_url,
        p.content,
        (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'url', image_url,
                    'order', display_order
                ) ORDER BY display_order
            )
            FROM post_images
            WHERE post_id = p.id
        ) as images,
        CASE
            WHEN ST_Distance(p.location, user_location) < 500 THEN '500m以内'
            WHEN ST_Distance(p.location, user_location) < 1000 THEN '1km以内'
            WHEN ST_Distance(p.location, user_location) < 2000 THEN '2km以内'
            ELSE '5km以内'
        END as distance_range,
        p.like_count,
        p.comment_count,
        EXISTS(
            SELECT 1 FROM likes
            WHERE post_id = p.id AND user_id = auth.uid()
        ) as is_liked,
        p.created_at
    FROM posts p
    JOIN profiles prof ON p.user_id = prof.id
    WHERE
        p.expires_at > NOW()
        AND ST_DWithin(p.location, user_location, radius_meters)
        AND NOT EXISTS (
            SELECT 1 FROM blocks
            WHERE blocker_id = auth.uid() AND blocked_id = p.user_id
        )
    ORDER BY p.created_at DESC
    LIMIT page_limit
    OFFSET page_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. マップ用投稿取得関数
-- 地図表示用に投稿の位置とプレビューを取得（最大200件）
-- ============================================

CREATE OR REPLACE FUNCTION get_map_posts(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    user_radius_km INT
)
RETURNS TABLE (
    post_id UUID,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    preview TEXT,
    has_image BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    user_location GEOGRAPHY;
    radius_meters INT;
BEGIN
    user_location := ST_MakePoint(user_lng, user_lat)::geography;
    radius_meters := user_radius_km * 1000;

    RETURN QUERY
    SELECT
        p.id,
        ST_Y(p.location::geometry) as lat,
        ST_X(p.location::geometry) as lng,
        LEFT(p.content, 30) || CASE WHEN LENGTH(p.content) > 30 THEN '...' ELSE '' END as preview,
        EXISTS(SELECT 1 FROM post_images WHERE post_id = p.id) as has_image,
        p.created_at
    FROM posts p
    WHERE
        p.expires_at > NOW()
        AND ST_DWithin(p.location, user_location, radius_meters)
        AND NOT EXISTS (
            SELECT 1 FROM blocks
            WHERE blocker_id = auth.uid() AND blocked_id = p.user_id
        )
    ORDER BY p.created_at DESC
    LIMIT 200;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. 期限切れ投稿削除関数
-- 24時間経過した投稿を一括削除
-- ============================================

CREATE OR REPLACE FUNCTION delete_expired_posts()
RETURNS void AS $$
BEGIN
    DELETE FROM posts WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. いいね数更新トリガー
-- ============================================

-- いいね追加時にlike_countをインクリメント
CREATE OR REPLACE FUNCTION increment_like_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER like_added
AFTER INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION increment_like_count();

-- いいね削除時にlike_countをデクリメント
CREATE OR REPLACE FUNCTION decrement_like_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET like_count = like_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER like_removed
AFTER DELETE ON likes
FOR EACH ROW
EXECUTE FUNCTION decrement_like_count();

-- ============================================
-- 6. コメント数更新トリガー
-- ============================================

-- コメント追加時にcomment_countをインクリメント
CREATE OR REPLACE FUNCTION increment_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER comment_added
AFTER INSERT ON comments
FOR EACH ROW
EXECUTE FUNCTION increment_comment_count();

-- コメント削除時にcomment_countをデクリメント
CREATE OR REPLACE FUNCTION decrement_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER comment_removed
AFTER DELETE ON comments
FOR EACH ROW
EXECUTE FUNCTION decrement_comment_count();

-- ============================================
-- 7. 定期実行設定（pg_cron）
-- 期限切れ投稿を毎時0分に自動削除
-- 注意: pg_cronが利用できない場合はEdge Functionで代替
-- ============================================

-- SELECT cron.schedule(
--     'delete-expired-posts',
--     '0 * * * *',
--     $$SELECT delete_expired_posts()$$
-- );
