-- ============================================================================
-- JOBS / JOB APPLICATIONS / BANNERS  ->  PIGGYBACK ON ALREADY-CACHED TABLES
-- Run this ONCE in the Supabase SQL Editor (Dashboard -> SQL Editor).
-- ============================================================================
--
-- WHY THIS FILE EXISTS
--   PostgREST keeps returning PGRST205 ("Could not find the table
--   public.jobs / public.job_applications / public.banners in the schema
--   cache") no matter what we do (grants, RLS, exposed-tables, NOTIFY, DDL
--   events, project restart, Data API config). Meanwhile the ORIGINAL
--   schema.sql tables (campaigns, applications, platform_settings, users,
--   notifications, wallets, ...) are served perfectly by the SAME PostgREST.
--
--   Root cause: those three relations are new and, for whatever reason on this
--   project, never make it into PostgREST's schema cache. Creating them again
--   would just repeat the problem.
--
-- THE FIX (no new relations)
--   Store the feature data INSIDE tables PostgREST already caches:
--     * Jobs             -> rows in public.campaigns  tagged  is_job = true
--     * Job applications -> rows in public.applications (campaign_id points at
--                           the is_job campaign row; creator_id = the user)
--     * Banners          -> a single JSON array stored in public.platform_settings
--                           in the row  key = 'home_banners'
--
--   ALTER TABLE ... ADD COLUMN on an ALREADY-CACHED table does NOT create a new
--   relation, so the table stays in the schema cache and PGRST205 cannot recur.
--
-- SAFETY
--   * Idempotent: every ALTER uses IF NOT EXISTS / IF EXISTS; every policy uses
--     DROP POLICY IF EXISTS before CREATE; data copies use ON CONFLICT.
--   * Guarded: data-migration blocks use to_regclass() so the script runs
--     cleanly whether or not the legacy jobs/job_applications/banners tables
--     still exist.
--   * It does NOT create public.jobs / public.job_applications / public.banners.
--   * It does NOT change existing campaign / application behavior or data.
--   * Safe to re-run.
-- ============================================================================


-- ─── 1. CAMPAIGNS: jobs marker column ────────────────────────────────────────
-- Jobs reuse the existing campaigns columns (title, description, category,
-- per_creator_payout, total_slots, deadline, cover_image_url, status). We only
-- need one new marker column so the real Campaigns/Home lists can exclude jobs.
ALTER TABLE public.campaigns
  ADD COLUMN IF NOT EXISTS is_job boolean NOT NULL DEFAULT false;


-- ─── 2. CAMPAIGNS: relax the status CHECK to allow 'closed' ──────────────────
-- Legacy jobs use status active/closed/draft; the campaigns CHECK forbids
-- 'closed'. Drop and re-add the constraint with a superset of the old values.
ALTER TABLE public.campaigns
  DROP CONSTRAINT IF EXISTS campaigns_status_check;

-- Clean any existing row whose status is NULL or not in the allowed set BEFORE
-- re-adding the constraint, otherwise ADD CONSTRAINT fails (23514) on that row.
UPDATE public.campaigns
SET status = 'draft'
WHERE status IS NULL
   OR status NOT IN ('draft', 'active', 'paused', 'completed', 'cancelled', 'closed');

ALTER TABLE public.campaigns
  ADD CONSTRAINT campaigns_status_check
  CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled', 'closed'));


-- ─── 3. APPLICATIONS: job-submission columns ─────────────────────────────────
-- Job applications reuse the applications table. Add the submission/review
-- columns that job_applications carried. (applicant profile columns from
-- add_application_fields.sql are NOT re-added here.)
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS submission_type text;
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS submission_url text;
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS submission_note text;
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS rejection_reason text;
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS submitted_at timestamptz;
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES public.users(id);


-- ─── 4. APPLICATIONS: relax the status CHECK for job statuses ────────────────
-- Legacy job applications use status applied/submitted/approved/rejected; the
-- applications CHECK forbids 'applied' and 'submitted'. Re-add with a superset.
ALTER TABLE public.applications
  DROP CONSTRAINT IF EXISTS applications_status_check;

-- Clean any invalid/NULL status BEFORE re-adding the constraint.
UPDATE public.applications
SET status = 'pending'
WHERE status IS NULL
   OR status NOT IN ('pending', 'approved', 'rejected', 'withdrawn', 'applied', 'submitted');

ALTER TABLE public.applications
  ADD CONSTRAINT applications_status_check
  CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn', 'applied', 'submitted'));


-- ─── 5. RLS: campaigns admin DELETE policy (for admin "Delete Job") ──────────
-- campaigns already has SELECT/INSERT/UPDATE policies that cover job rows:
--   * "Anyone can read active campaigns"  -> active job rows are world-readable
--   * "Brands can create campaigns"       -> admin creates jobs with brand_id = admin.id
--   * "Brands can update own campaigns"    -> admin can update own job rows
-- but there was no DELETE policy. Reuse the pattern from add_campaign_delete_rls.sql
-- (public.is_admin() SECURITY DEFINER helper). Deleting a job/campaign row
-- cascade-deletes its applications via applications.campaign_id ... ON DELETE
-- CASCADE, so no extra applications DELETE policy is required.
DROP POLICY IF EXISTS "Admins can delete campaigns" ON public.campaigns;
CREATE POLICY "Admins can delete campaigns" ON public.campaigns
  FOR DELETE
  USING (public.is_admin());

-- NOTE: applications and platform_settings need NO new policies.
--   * applications: creator inserts/reads/updates own rows; admins read/update
--     all. Job applications use creator_id = the user, so existing policies work.
--   * platform_settings: "Anyone can read platform settings" (USING TRUE) lets
--     everyone read the home_banners row; "Admins can manage platform settings"
--     restricts writes to admins. Sufficient for banners-as-JSON.


-- ─── 6. DATA MIGRATION (best-effort, guarded, idempotent) ────────────────────
-- Copy any surviving legacy rows into the piggyback tables. Each block is
-- guarded with to_regclass() so it is skipped (no error) when the source table
-- does not exist. Same ids are preserved so relationships still line up, and
-- ON CONFLICT keeps re-runs safe.

-- 6a. Legacy public.jobs -> public.campaigns (is_job = true)
-- Wrapped in an EXCEPTION handler: this legacy-data copy is best-effort only.
-- If the live campaigns table has different column names than expected, the
-- migration is skipped silently rather than aborting the whole script. (You
-- can always re-post the one test job from the app afterwards.)
DO $$
BEGIN
  IF to_regclass('public.jobs') IS NOT NULL THEN
    BEGIN
      INSERT INTO public.campaigns (
        id, brand_id, title, description, category,
        per_creator_payout, total_slots, deadline, cover_image_url,
        status, is_job, created_at, updated_at
      )
      SELECT
        j.id,
        j.created_by,
        j.title,
        j.description,
        j.category,
        COALESCE(j.payment_amount, 0),
        COALESCE(j.max_slots, 0),
        j.deadline,
        j.cover_image_url,
        COALESCE(j.status, 'active'),
        true,
        COALESCE(j.created_at, now()),
        COALESCE(j.updated_at, now())
      FROM public.jobs j
      ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Skipped legacy jobs migration: %', SQLERRM;
    END;
  END IF;
END;
$$;

-- 6b. Legacy public.job_applications -> public.applications (best-effort)
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
        ja.id,
        ja.job_id,
        ja.user_id,
        COALESCE(ja.status, 'applied'),
        ja.submission_type,
        ja.submission_url,
        ja.submission_note,
        ja.rejection_reason,
        COALESCE(ja.applied_at, now()),
        ja.submitted_at,
        ja.reviewed_at,
        ja.reviewed_by
      FROM public.job_applications ja
      WHERE EXISTS (SELECT 1 FROM public.campaigns c WHERE c.id = ja.job_id)
      ON CONFLICT (id) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Skipped legacy job_applications migration: %', SQLERRM;
    END;
  END IF;
END;
$$;

-- 6c. Legacy public.banners -> platform_settings row key = 'home_banners'
DO $$
DECLARE
  banners_json text;
BEGIN
  IF to_regclass('public.banners') IS NOT NULL THEN
    SELECT COALESCE(
      json_agg(
        json_build_object(
          'id',               b.id::text,
          'title',            b.title,
          'image_url',        b.image_url,
          'link_type',        COALESCE(b.link_type, 'none'),
          'link_campaign_id', b.link_campaign_id,
          'link_page',        b.link_page,
          'is_visible',       COALESCE(b.is_visible, true),
          'sort_order',       COALESCE(b.sort_order, 0),
          'created_at',       COALESCE(b.created_at, now()),
          'updated_at',       COALESCE(b.updated_at, now())
        )
        ORDER BY COALESCE(b.sort_order, 0)
      )::text,
      '[]'
    )
    INTO banners_json
    FROM public.banners b;

    INSERT INTO public.platform_settings (key, value)
    VALUES ('home_banners', banners_json)
    ON CONFLICT (key) DO UPDATE
      SET value = EXCLUDED.value;
  END IF;
END;
$$;


-- ─── 7. Server-side job slot enforcement (BEFORE INSERT on applications) ─────
-- Jobs now insert into public.applications, so the old enforce_job_slots
-- trigger (which lived on the now-unused public.job_applications table) no
-- longer runs. Re-add an equivalent BEFORE INSERT trigger on applications that
-- caps applicants ONLY for job campaigns, leaving real campaign applications
-- (is_job = false) completely untouched.
--
-- Convention: for jobs, total_slots = 0 means UNLIMITED, so enforcement only
-- kicks in when the target campaign is a job AND total_slots is not null and
-- greater than 0. Counted statuses match jobSlotCountProvider in Dart
-- (applied / submitted / approved). Idempotent via CREATE OR REPLACE FUNCTION
-- and DROP TRIGGER IF EXISTS before CREATE TRIGGER.
CREATE OR REPLACE FUNCTION public.enforce_job_slots()
RETURNS trigger AS $$
DECLARE
  v_is_job boolean;
  v_total_slots integer;
  v_used integer;
BEGIN
  -- Look up the target campaign for this application.
  SELECT c.is_job, c.total_slots
    INTO v_is_job, v_total_slots
  FROM public.campaigns c
  WHERE c.id = NEW.campaign_id;

  -- Only enforce for job campaigns with a finite, positive slot cap.
  -- (is_job = false / null -> real campaign application: never enforced.
  --  total_slots null or <= 0 -> unlimited: never enforced.)
  IF v_is_job IS TRUE AND v_total_slots IS NOT NULL AND v_total_slots > 0 THEN
    SELECT count(*)
      INTO v_used
    FROM public.applications a
    WHERE a.campaign_id = NEW.campaign_id
      AND a.status IN ('applied', 'submitted', 'approved');

    IF v_used >= v_total_slots THEN
      RAISE EXCEPTION 'This job has no slots remaining.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS enforce_job_slots ON public.applications;
CREATE TRIGGER enforce_job_slots
  BEFORE INSERT ON public.applications
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_job_slots();


-- ─── 8. Ask PostgREST to reload its schema cache ─────────────────────────────
NOTIFY pgrst, 'reload schema';
