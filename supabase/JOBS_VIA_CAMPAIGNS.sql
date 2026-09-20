-- ============================================================================
-- JOBS_VIA_CAMPAIGNS.sql  (FINAL — uses the ACTUAL live campaigns columns)
--
-- Jobs/banners standalone tables cannot be served by this project's PostgREST
-- (PGRST205). So Jobs ride on the ALREADY-WORKING `campaigns` table
-- (tagged is_job = true) and job applications on the `applications` table.
--
-- The live campaigns table uses these ACTUAL columns (verified):
--   payout_per_creator (numeric)   <- job payment_amount
--   slots (integer)                <- job max_slots (0 = unlimited)
--   cover_image (text)             <- job cover_image_url
--   budget (numeric), category, title, description, deadline, status, brand_id
--
-- Run this WHOLE file once in the Supabase SQL Editor. Idempotent & safe.
-- It only ALTERs already-cached tables (no new relation), so PGRST205 cannot
-- happen. Legacy-copy blocks are best-effort (wrapped) and can be skipped.
-- ============================================================================

-- ─── 1. CAMPAIGNS: add the is_job marker ─────────────────────────────────────
ALTER TABLE public.campaigns
  ADD COLUMN IF NOT EXISTS is_job boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS campaigns_is_job_idx ON public.campaigns(is_job);

-- ─── 2. CAMPAIGNS: allow 'closed' status (jobs can be closed) ────────────────
-- Clean any invalid/NULL status first so the new CHECK can be applied.
ALTER TABLE public.campaigns DROP CONSTRAINT IF EXISTS campaigns_status_check;
UPDATE public.campaigns
SET status = 'active'
WHERE status IS NULL
   OR status NOT IN ('draft','active','paused','completed','cancelled','closed');
ALTER TABLE public.campaigns
  ADD CONSTRAINT campaigns_status_check
  CHECK (status IN ('draft','active','paused','completed','cancelled','closed'));

-- ─── 3. APPLICATIONS: add job-submission columns ─────────────────────────────
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_type text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_url text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_note text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS rejection_reason text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submitted_at timestamptz;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES public.users(id);

-- ─── 4. APPLICATIONS: allow job statuses (applied/submitted) ─────────────────
ALTER TABLE public.applications DROP CONSTRAINT IF EXISTS applications_status_check;
UPDATE public.applications
SET status = 'pending'
WHERE status IS NULL
   OR status NOT IN ('pending','approved','rejected','withdrawn','applied','submitted');
ALTER TABLE public.applications
  ADD CONSTRAINT applications_status_check
  CHECK (status IN ('pending','approved','rejected','withdrawn','applied','submitted'));

-- ─── 5. SLOT ENFORCEMENT for job applications (scoped to is_job campaigns) ───
CREATE OR REPLACE FUNCTION public.enforce_job_slots()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_is_job  boolean;
  v_slots   integer;
  v_count   integer;
BEGIN
  SELECT is_job, slots INTO v_is_job, v_slots
  FROM public.campaigns WHERE id = NEW.campaign_id;

  -- Only enforce for job campaigns with a finite, positive slot cap.
  IF v_is_job IS TRUE AND v_slots IS NOT NULL AND v_slots > 0 THEN
    SELECT count(*) INTO v_count
    FROM public.applications
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

-- ─── 6. Admin DELETE policy on campaigns (for the "Delete Job" action) ───────
DROP POLICY IF EXISTS "Admins can delete campaigns" ON public.campaigns;
CREATE POLICY "Admins can delete campaigns" ON public.campaigns
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

-- ─── 7. BEST-EFFORT legacy data copy (skipped silently on any mismatch) ──────
-- Copies the one test job/banner if the old tables still exist. Wrapped so a
-- column mismatch never aborts the script.
DO $$
BEGIN
  IF to_regclass('public.jobs') IS NOT NULL THEN
    BEGIN
      INSERT INTO public.campaigns (
        id, brand_id, title, description, category,
        payout_per_creator, slots, deadline, cover_image, status, is_job,
        budget, created_at, updated_at
      )
      SELECT
        j.id, j.created_by, j.title, j.description, j.category,
        COALESCE(j.payment_amount, 0), COALESCE(j.max_slots, 0),
        j.deadline, j.cover_image_url, COALESCE(j.status, 'active'), true,
        0, COALESCE(j.created_at, now()), COALESCE(j.updated_at, now())
      FROM public.jobs j
      ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Skipped legacy jobs copy: %', SQLERRM;
    END;
  END IF;
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.job_applications') IS NOT NULL THEN
    BEGIN
      INSERT INTO public.applications (
        id, campaign_id, creator_id, status,
        submission_type, submission_url, submission_note, rejection_reason,
        created_at, submitted_at, reviewed_at, reviewed_by
      )
      SELECT
        ja.id, ja.job_id, ja.user_id, COALESCE(ja.status, 'applied'),
        ja.submission_type, ja.submission_url, ja.submission_note,
        ja.rejection_reason, COALESCE(ja.applied_at, now()),
        ja.submitted_at, ja.reviewed_at, ja.reviewed_by
      FROM public.job_applications ja
      WHERE EXISTS (SELECT 1 FROM public.campaigns c WHERE c.id = ja.job_id)
      ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Skipped legacy job_applications copy: %', SQLERRM;
    END;
  END IF;
END;
$$;

-- ─── 8. Reload PostgREST (campaigns/applications are already cached anyway) ──
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- After running: install the latest APK, then as admin -> Post Job. It creates
-- a row in campaigns with is_job=true and will appear on the Jobs screen (and
-- NOT on the Campaigns screen). No PGRST205 possible — campaigns is cached.
-- ============================================================================
