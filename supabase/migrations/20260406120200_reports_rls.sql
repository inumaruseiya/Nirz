-- Phase 10-2-3: RLS for reports (authenticated INSERT own row; SELECT own only)

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY reports_select_own
  ON public.reports
  FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);

CREATE POLICY reports_insert_own
  ON public.reports
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);
