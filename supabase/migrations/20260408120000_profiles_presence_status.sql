-- Phase 11-1-5: Optional user presence for settings / profile UI only (FR-STATUS-01, not on feed cards FR-STATUS-02).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS presence_status text;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_presence_status_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_presence_status_check
  CHECK (
    presence_status IS NULL
    OR presence_status IN ('free', 'working', 'out')
  );

COMMENT ON COLUMN public.profiles.presence_status IS
  'Optional lightweight status: free=暇, working=作業中, out=外出中. Not shown on feed cards.';
