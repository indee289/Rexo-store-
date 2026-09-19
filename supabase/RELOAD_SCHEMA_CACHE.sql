-- ============================================================================
-- FIX: "The requested data was not found." on every jobs/banners screen
-- even though the tables and 8 policies exist.
--
-- ROOT CAUSE: PostgREST (the REST API layer Supabase uses) caches the database
-- schema. When new tables (jobs, job_applications, banners) are created, the
-- cache is NOT automatically refreshed, so the API returns PGRST205
-- "Could not find the table ... in the schema cache" — which the app maps to
-- "not found". The tables are fine; the API just doesn't see them yet.
--
-- FIX: tell PostgREST to reload its schema cache.
-- ============================================================================

NOTIFY pgrst, 'reload schema';

-- If NOTIFY alone doesn't take effect immediately, this also forces a reload:
SELECT pg_notify('pgrst', 'reload schema');

-- ============================================================================
-- ALSO: align submission column name. The app writes 'submission_url' but an
-- earlier schema had 'submission_proof'. Make sure submission_url exists.
-- (Safe no-op if it already exists.)
-- ============================================================================
ALTER TABLE public.job_applications
  ADD COLUMN IF NOT EXISTS submission_url text;

-- If a legacy 'submission_proof' column holds data, copy it over once:
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='job_applications'
      AND column_name='submission_proof'
  ) THEN
    UPDATE public.job_applications
    SET submission_url = submission_proof
    WHERE submission_url IS NULL AND submission_proof IS NOT NULL;
  END IF;
END $$;

-- Reload once more after the column change.
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- After running this, wait ~10 seconds, then Retry in the app.
-- Also: Supabase Dashboard has a manual option —
--   Settings -> API -> "Reload schema cache" (or restart the project).
-- ============================================================================
