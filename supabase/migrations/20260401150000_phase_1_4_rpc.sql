-- Phase 1-4: RPC functions (implementation plan 1-4-1 through 1-4-6)
-- SECURITY DEFINER: enforce feed radius, TTL, and create_post rules in one place.
-- See docs/detailed-design-local-sns-flutter-supabase.md §8.1, §8.2

-- -----------------------------------------------------------------------------
-- 1-4-1 .. 1-4-4 get_local_feed
-- 1-4-2: ST_DWithin(..., 5000) + expires_at > now() enforced here
-- 1-4-3: reaction_count per post
-- 1-4-4: keyset on (created_at, id) for newest; for popular, (reaction_count, created_at, id)
--         using reaction_count of the cursor post resolved by (cursor_created_at, cursor_id)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_local_feed(
  p_lat double precision,
  p_lng double precision,
  p_limit integer DEFAULT 20,
  p_cursor_created_at timestamptz DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL,
  p_sort text DEFAULT 'newest'
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
  v_sort text := lower(trim(coalesce(p_sort, 'newest')));
  v_limit int := coalesce(p_limit, 20);
  v_cursor_rc bigint;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_lat IS NULL OR p_lng IS NULL
     OR p_lat < -90 OR p_lat > 90
     OR p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'invalid lat/lng' USING ERRCODE = '22023';
  END IF;

  IF v_limit < 1 OR v_limit > 100 THEN
    RAISE EXCEPTION 'limit must be between 1 and 100' USING ERRCODE = '22023';
  END IF;

  v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;

  IF p_cursor_id IS NOT NULL AND p_cursor_created_at IS NOT NULL AND v_sort = 'popular' THEN
    SELECT COUNT(*)::bigint INTO v_cursor_rc
    FROM public.reactions r
    WHERE r.post_id = p_cursor_id;
  END IF;

  IF v_sort IN ('new', 'newest') THEN
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
      COALESCE(rc.cnt, 0)::bigint AS reaction_count,
      COALESCE(pr.name, '')::text AS author_name,
      ST_Distance(p.location, v_point, false) AS distance_meters
    FROM public.posts p
    LEFT JOIN public.profiles pr ON pr.id = p.user_id
    LEFT JOIN LATERAL (
      SELECT COUNT(*)::bigint AS cnt
      FROM public.reactions r
      WHERE r.post_id = p.id
    ) rc ON true
    WHERE p.expires_at > now()
      AND ST_DWithin(p.location, v_point, 5000, false)
      AND (
        p_cursor_created_at IS NULL
        OR p_cursor_id IS NULL
        OR (p.created_at, p.id) < (p_cursor_created_at, p_cursor_id)
      )
    ORDER BY p.created_at DESC, p.id DESC
    LIMIT v_limit;

  ELSIF v_sort = 'popular' THEN
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
      COALESCE(rc.cnt, 0)::bigint AS reaction_count,
      COALESCE(pr.name, '')::text AS author_name,
      ST_Distance(p.location, v_point, false) AS distance_meters
    FROM public.posts p
    LEFT JOIN public.profiles pr ON pr.id = p.user_id
    LEFT JOIN LATERAL (
      SELECT COUNT(*)::bigint AS cnt
      FROM public.reactions r
      WHERE r.post_id = p.id
    ) rc ON true
    WHERE p.expires_at > now()
      AND ST_DWithin(p.location, v_point, 5000, false)
      AND (
        p_cursor_created_at IS NULL
        OR p_cursor_id IS NULL
        OR (
          (COALESCE(rc.cnt, 0), p.created_at, p.id) < (
            COALESCE(v_cursor_rc, 0),
            p_cursor_created_at,
            p_cursor_id
          )
        )
      )
    ORDER BY COALESCE(rc.cnt, 0) DESC, p.created_at DESC, p.id DESC
    LIMIT v_limit;

  ELSE
    RAISE EXCEPTION 'invalid sort: %', p_sort USING ERRCODE = '22023';
  END IF;
END;
$$;

-- -----------------------------------------------------------------------------
-- 1-4-5 create_post — server-enforced expires_at = now() + 24 hours
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_post(
  p_content text,
  p_image_url text DEFAULT NULL,
  p_lat_blurred double precision DEFAULT NULL,
  p_lng_blurred double precision DEFAULT NULL
)
RETURNS SETOF public.posts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_new_id uuid;
  v_content text;
  v_image text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  v_content := trim(coalesce(p_content, ''));
  IF length(v_content) = 0 THEN
    RAISE EXCEPTION 'content is required' USING ERRCODE = '22023';
  END IF;

  IF p_lat_blurred IS NULL OR p_lng_blurred IS NULL
     OR p_lat_blurred < -90 OR p_lat_blurred > 90
     OR p_lng_blurred < -180 OR p_lng_blurred > 180 THEN
    RAISE EXCEPTION 'invalid blurred coordinates' USING ERRCODE = '22023';
  END IF;

  v_image := NULLIF(trim(coalesce(p_image_url, '')), '');

  INSERT INTO public.posts (user_id, content, image_url, location, expires_at)
  VALUES (
    v_uid,
    v_content,
    v_image,
    ST_SetSRID(ST_MakePoint(p_lng_blurred, p_lat_blurred), 4326)::geography,
    now() + interval '24 hours'
  )
  RETURNING posts.id INTO v_new_id;

  RETURN QUERY
  SELECT *
  FROM public.posts
  WHERE posts.id = v_new_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- 1-4-6 get_post_detail — single post + reaction aggregate + comment count
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_post_detail(p_post_id uuid)
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
  author_name text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_post_id IS NULL THEN
    RAISE EXCEPTION 'post id is required' USING ERRCODE = '22023';
  END IF;

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
    COALESCE(pr.name, '')::text AS author_name
  FROM public.posts p
  LEFT JOIN public.profiles pr ON pr.id = p.user_id
  WHERE p.id = p_post_id;
END;
$$;

-- Grants: callable by authenticated clients only
REVOKE ALL ON FUNCTION public.get_local_feed(double precision, double precision, integer, timestamptz, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_local_feed(double precision, double precision, integer, timestamptz, uuid, text) TO authenticated;

REVOKE ALL ON FUNCTION public.create_post(text, text, double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_post(text, text, double precision, double precision) TO authenticated;

REVOKE ALL ON FUNCTION public.get_post_detail(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_post_detail(uuid) TO authenticated;
