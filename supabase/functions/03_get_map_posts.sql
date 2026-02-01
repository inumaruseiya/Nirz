-- マップ用投稿取得関数
-- 地図表示用に投稿の位置とプレビューを取得（最大200件）
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
