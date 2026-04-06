-- Phase 10-1-3: Server-side NG word filter (FR-MOD-01)
-- Matches client logic: case-insensitive substring against public.ng_words.word

CREATE OR REPLACE FUNCTION public.content_violates_ng_words(p_content text)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.ng_words w
    WHERE length(trim(w.word)) > 0
      AND strpos(lower(p_content), lower(trim(w.word))) > 0
  );
$$;

COMMENT ON FUNCTION public.content_violates_ng_words(text) IS
  'True if p_content contains any NG substring from ng_words (Phase 10-1-3, FR-MOD-01)';

REVOKE ALL ON FUNCTION public.content_violates_ng_words(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.content_violates_ng_words(text) FROM anon;
REVOKE ALL ON FUNCTION public.content_violates_ng_words(text) FROM authenticated;

-- -----------------------------------------------------------------------------
-- create_post: reject prohibited content (same rules as client)
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

  IF public.content_violates_ng_words(v_content) THEN
    RAISE EXCEPTION 'content contains prohibited expressions'
      USING ERRCODE = 'P0001';
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
-- comments: BEFORE INSERT trigger (direct table inserts bypass create_post)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.comments_enforce_ng_words()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v text;
BEGIN
  v := trim(coalesce(NEW.content, ''));
  IF length(v) = 0 THEN
    RAISE EXCEPTION 'content is required' USING ERRCODE = '22023';
  END IF;
  IF public.content_violates_ng_words(v) THEN
    RAISE EXCEPTION 'content contains prohibited expressions'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS comments_enforce_ng_words_trigger ON public.comments;

CREATE TRIGGER comments_enforce_ng_words_trigger
  BEFORE INSERT ON public.comments
  FOR EACH ROW
  EXECUTE PROCEDURE public.comments_enforce_ng_words();
