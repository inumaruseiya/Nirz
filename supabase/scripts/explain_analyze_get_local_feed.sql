-- -----------------------------------------------------------------------------
-- Phase 12-6-1: EXPLAIN ANALYZE for public.get_local_feed (NFR-PERF-01)
--
-- Goal: confirm index-friendly plans (GiST on posts.location; btree on
-- reactions.post_id after migration 20260410090000).
-- The implementation plan targets ~500ms round-trip; absolute ms depends on
-- data volume and hardware — use this script to compare before/after changes.
--
-- Run (local):  supabase db start && supabase db psql
-- Then paste this file, after replacing the UUID with a real auth.users.id
-- (any row from auth.users). If auth.uid() stays null, the RPC raises
-- "not authenticated".
-- -----------------------------------------------------------------------------
SELECT set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000000',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT *
FROM public.get_local_feed(
  p_lat := 35.681236,
  p_lng := 139.767125,
  p_limit := 20,
  p_cursor_created_at := NULL,
  p_cursor_id := NULL,
  p_sort := 'newest'
);

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT *
FROM public.get_local_feed(
  p_lat := 35.681236,
  p_lng := 139.767125,
  p_limit := 20,
  p_cursor_created_at := NULL,
  p_cursor_id := NULL,
  p_sort := 'popular'
);
