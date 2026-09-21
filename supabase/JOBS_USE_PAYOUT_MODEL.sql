-- ============================================================================
-- Switch jobs marker from the newly-added is_job column (which PostgREST's
-- schema cache refuses to serve on this project) to the EXISTING, already-
-- cached payout_model column. payout_model = 'job' now marks a job row.
--
-- Run this WHOLE file once in the Supabase SQL Editor. Safe + idempotent.
-- No new column is created, so PostgREST cannot 42703/PGRST205 on it.
-- ============================================================================

-- 1. Migrate any rows that were already tagged is_job = true (if that column
--    exists) over to payout_model = 'job'.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='campaigns' AND column_name='is_job'
  ) THEN
    UPDATE public.campaigns SET payout_model = 'job' WHERE is_job = true;
  END IF;
END $$;

-- 2. Slot-enforcement trigger keyed on payout_model = 'job' (not is_job).
CREATE OR REPLACE FUNCTION public.enforce_job_slots()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_model text; v_slots integer; v_count integer;
BEGIN
  SELECT payout_model, slots INTO v_model, v_slots
  FROM public.campaigns WHERE id = NEW.campaign_id;
  IF v_model = 'job' AND v_slots IS NOT NULL AND v_slots > 0 THEN
    SELECT count(*) INTO v_count FROM public.applications
    WHERE campaign_id = NEW.campaign_id
      AND status IN ('applied','submitted','approved');
    IF v_count >= v_slots THEN
      RAISE EXCEPTION 'This job has no slots remaining.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS enforce_job_slots ON public.applications;
CREATE TRIGGER enforce_job_slots
  BEFORE INSERT ON public.applications
  FOR EACH ROW EXECUTE FUNCTION public.enforce_job_slots();

-- 3. Reload (payout_model is already cached; this is just belt-and-suspenders).
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- After running: install the latest APK, then Post Job. It writes a campaigns
-- row with payout_model = 'job'; Jobs screens filter on payout_model = 'job'
-- and the Campaigns/Home lists exclude it with payout_model <> 'job'. Because
-- payout_model already existed and is cached, no schema-cache error can occur.
-- ============================================================================
