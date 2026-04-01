-- Phase 1-3: Row Level Security (implementation plan 1-3-1 through 1-3-5)
-- Geographic filtering for feed is enforced in RPC (get_local_feed), not in posts SELECT policy.

-- -----------------------------------------------------------------------------
-- 1-3-1 profiles: authenticated SELECT all; UPDATE own row only
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select_authenticated
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY profiles_update_own
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- -----------------------------------------------------------------------------
-- 1-3-2 posts: authenticated SELECT; INSERT only as self
-- 1-3-3 posts: DELETE own posts only
-- -----------------------------------------------------------------------------
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY posts_select_authenticated
  ON public.posts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY posts_insert_own
  ON public.posts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY posts_delete_own
  ON public.posts
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 1-3-4 reactions: authenticated SELECT; write only own rows
-- -----------------------------------------------------------------------------
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY reactions_select_authenticated
  ON public.reactions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY reactions_insert_own
  ON public.reactions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY reactions_update_own
  ON public.reactions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY reactions_delete_own
  ON public.reactions
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 1-3-5 comments: authenticated SELECT; INSERT as self only
-- -----------------------------------------------------------------------------
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY comments_select_authenticated
  ON public.comments
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY comments_insert_own
  ON public.comments
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
