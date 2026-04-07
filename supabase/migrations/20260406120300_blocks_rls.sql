-- Phase 10-3-2: RLS for blocks (authenticated users manage own block list)

ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

-- Blocker can see rows they created (for future "blocked users" UI / idempotency checks).
CREATE POLICY blocks_select_as_blocker
  ON public.blocks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = blocker_id);

-- Only insert as self as blocker; blocked_id must differ (table CHECK enforces too).
CREATE POLICY blocks_insert_as_blocker
  ON public.blocks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = blocker_id AND blocked_id <> auth.uid());

-- Unblock / undo (optional; same user as blocker only).
CREATE POLICY blocks_delete_as_blocker
  ON public.blocks
  FOR DELETE
  TO authenticated
  USING (auth.uid() = blocker_id);
