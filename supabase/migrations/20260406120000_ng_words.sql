-- Phase 10-1-1: NG word list (FR-MOD-01) — server-managed list, optional seed for local dev

CREATE TABLE public.ng_words (
  word text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.ng_words IS 'Moderation: prohibited substrings for client/server filters (FR-MOD-01)';

ALTER TABLE public.ng_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY ng_words_select_authenticated
  ON public.ng_words
  FOR SELECT
  TO authenticated
  USING (true);
