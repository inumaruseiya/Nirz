-- Phase 1-2: Tables (implementation plan 1-2-1 through 1-2-10)
-- See docs/implementation-plan.md §1-2

-- -----------------------------------------------------------------------------
-- 1-2-1 profiles
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT '',
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'User profile row; id matches auth.users.id (FR-AUTH-02)';

-- -----------------------------------------------------------------------------
-- 1-2-2 Auto-create profile on signup
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, created_at)
  VALUES (
    NEW.id,
    COALESCE(
      NULLIF(trim(NEW.raw_user_meta_data ->> 'name'), ''),
      NULLIF(trim(NEW.raw_user_meta_data ->> 'full_name'), ''),
      ''
    ),
    now()
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 1-2-3 posts (+ 1-2-4 .. 1-2-6 indexes)
-- -----------------------------------------------------------------------------
CREATE TABLE public.posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  content text NOT NULL,
  image_url text,
  location geography (Point, 4326) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL
);

CREATE INDEX idx_posts_location ON public.posts USING gist (location);
CREATE INDEX idx_posts_expires_at ON public.posts (expires_at);
CREATE INDEX idx_posts_created_at ON public.posts (created_at DESC);

-- -----------------------------------------------------------------------------
-- 1-2-7 reactions
-- -----------------------------------------------------------------------------
CREATE TABLE public.reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  post_id uuid NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  type text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, post_id)
);

-- -----------------------------------------------------------------------------
-- 1-2-8 comments
-- -----------------------------------------------------------------------------
CREATE TABLE public.comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  post_id uuid NOT NULL REFERENCES public.posts (id) ON DELETE CASCADE,
  parent_comment_id uuid REFERENCES public.comments (id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_comments_post_id ON public.comments (post_id);

-- -----------------------------------------------------------------------------
-- 1-2-9 reports (MVP later — schema only)
-- -----------------------------------------------------------------------------
CREATE TABLE public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  target_type text NOT NULL,
  target_id uuid NOT NULL,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'open',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 1-2-10 blocks (MVP later — schema only)
-- -----------------------------------------------------------------------------
CREATE TABLE public.blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

CREATE INDEX idx_blocks_blocker_id ON public.blocks (blocker_id);
