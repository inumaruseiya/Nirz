-- タイムライン取得関数
-- 指定位置から範囲内の投稿を取得（ブロック・期限切れ除外）
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
