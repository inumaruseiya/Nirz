-- -----------------------------------------------------------------------------
-- Phase 12-6-3: Verify GiST index on posts.location (NFR-SCALE-02)
--
-- Migration 20260401130000_phase_1_2_tables.sql defines:
--   CREATE INDEX idx_posts_location ON public.posts USING gist (location);
--
-- After applying migrations, run this in psql (e.g. supabase db psql) and
-- confirm the plan uses a GiST index scan (Bitmap Index Scan on idx_posts_location
-- or similar), not a Seq Scan on large tables.
--
-- Example:
--   supabase db psql -f supabase/scripts/explain_gist_posts_location.sql
-- -----------------------------------------------------------------------------

-- Registered indexes on public.posts (sanity check)
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'posts'
ORDER BY indexname;

-- Geo filter equivalent to get_local_feed’s ST_DWithin(..., 5000) on posts alone
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT p.id
FROM public.posts p
WHERE p.expires_at > now()
  AND ST_DWithin(
    p.location,
    ST_SetSRID(ST_MakePoint(139.767125, 35.681236), 4326)::geography,
    5000,
    false
  )
ORDER BY p.created_at DESC, p.id DESC
LIMIT 20;
