-- Phase 8: post detail must respect same geo + TTL rules as get_local_feed (5km, not expired).
-- Replaces get_post_detail(uuid) with viewer lat/lng for distance_meters and visibility.

DROP FUNCTION IF EXISTS public.get_post_detail(uuid);

CREATE OR REPLACE FUNCTION public.get_post_detail(
  p_post_id uuid,
  p_lat double precision,
  p_lng double precision
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  content text,
  image_url text,
  location_lat double precision,
  location_lng double precision,
  created_at timestamptz,
  expires_at timestamptz,
  reaction_count bigint,
  comment_count bigint,
  author_name text,
  distance_meters double precision
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_point geography;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_post_id IS NULL THEN
    RAISE EXCEPTION 'post id is required' USING ERRCODE = '22023';
  END IF;

  IF p_lat IS NULL OR p_lng IS NULL
     OR p_lat < -90 OR p_lat > 90
     OR p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'invalid lat/lng' USING ERRCODE = '22023';
  END IF;

  v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;

  RETURN QUERY
  SELECT
    p.id,
    p.user_id,
    p.content,
    p.image_url,
    ST_Y(p.location::geometry) AS location_lat,
    ST_X(p.location::geometry) AS location_lng,
    p.created_at,
    p.expires_at,
    (SELECT COUNT(*)::bigint FROM public.reactions r WHERE r.post_id = p.id) AS reaction_count,
    (SELECT COUNT(*)::bigint FROM public.comments c WHERE c.post_id = p.id) AS comment_count,
    COALESCE(pr.name, '')::text AS author_name,
    ST_Distance(p.location, v_point, false) AS distance_meters
  FROM public.posts p
  LEFT JOIN public.profiles pr ON pr.id = p.user_id
  WHERE p.id = p_post_id
    AND p.expires_at > now()
    AND ST_DWithin(p.location, v_point, 5000, false);
END;
$$;

REVOKE ALL ON FUNCTION public.get_post_detail(uuid, double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_post_detail(uuid, double precision, double precision) TO authenticated;
