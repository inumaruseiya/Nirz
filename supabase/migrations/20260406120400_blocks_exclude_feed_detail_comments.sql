-- Phase 10-3-3: Exclude blocked users from feed, post detail, and comment reads (FR-MOD-03)

-- -----------------------------------------------------------------------------
-- get_local_feed: omit posts whose author is blocked by the viewer
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
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
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
      AND NOT EXISTS (
        SELECT 1 FROM public.blocks b
        WHERE b.blocker_id = v_uid AND b.blocked_id = p.user_id
      )
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
      AND NOT EXISTS (
        SELECT 1 FROM public.blocks b
        WHERE b.blocker_id = v_uid AND b.blocked_id = p.user_id
      )
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
-- get_post_detail: no row if author blocked; comment_count excludes blocked authors
-- -----------------------------------------------------------------------------
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
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
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
    (
      SELECT COUNT(*)::bigint
      FROM public.comments c
      WHERE c.post_id = p.id
        AND NOT EXISTS (
          SELECT 1 FROM public.blocks b
          WHERE b.blocker_id = v_uid AND b.blocked_id = c.user_id
        )
    ) AS comment_count,
    COALESCE(pr.name, '')::text AS author_name,
    ST_Distance(p.location, v_point, false) AS distance_meters
  FROM public.posts p
  LEFT JOIN public.profiles pr ON pr.id = p.user_id
  WHERE p.id = p_post_id
    AND p.expires_at > now()
    AND ST_DWithin(p.location, v_point, 5000, false)
    AND NOT EXISTS (
      SELECT 1 FROM public.blocks b
      WHERE b.blocker_id = v_uid AND b.blocked_id = p.user_id
    );
END;
$$;

-- -----------------------------------------------------------------------------
-- comments SELECT: hide comments authored by users blocked by viewer
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS comments_select_authenticated ON public.comments;

CREATE POLICY comments_select_authenticated
  ON public.comments
  FOR SELECT
  TO authenticated
  USING (
    NOT EXISTS (
      SELECT 1 FROM public.blocks b
      WHERE b.blocker_id = auth.uid() AND b.blocked_id = comments.user_id
    )
  );
