-- Phase 12-6-1 / NFR-PERF-01: speed up per-post reaction counts in get_local_feed (LATERAL subquery on reactions.post_id).
-- GiST on posts.location remains the primary geo filter (Phase 12-6-3).

CREATE INDEX IF NOT EXISTS idx_reactions_post_id
  ON public.reactions (post_id);
