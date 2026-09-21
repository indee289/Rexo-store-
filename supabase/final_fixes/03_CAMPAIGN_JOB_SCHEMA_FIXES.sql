-- ============================================================================
-- 03_CAMPAIGN_JOB_SCHEMA_FIXES.sql
-- Rexo — Campaign and Job Table Extensions
--
-- PURPOSE
--   All campaigns-table and applications-table ALTER statements required for
--   the Jobs-via-Campaigns architecture, campaign creation form fields,
--   extra rules/demo-asset fields, and job slot enforcement.
--
-- ARCHITECTURE NOTE — CRITICAL UNRESOLVED DISCREPANCY
--   The live database column names for the jobs-related fields are UNCERTAIN.
--   Two conflicting sets of names exist in the repository:
--
--   schema.sql (older snapshot):     per_creator_payout | total_slots | cover_image_url
--   JOBS_VIA_CAMPAIGNS.sql (claim):  payout_per_creator | slots       | cover_image
--
--   Flutter code split:
--     - create_campaign_screen.dart writes: per_creator_payout, total_slots, cover_image_url
--     - jobs_provider.dart writes:          payout_per_creator, slots, cover_image
--
--   ONE of these will fail at runtime. Verify the actual live columns with the
--   query in 99_VERIFICATION_QUERIES.sql BEFORE running this file.
--
--   This file uses the JOBS_VIA_CAMPAIGNS column names (payout_per_creator, slots,
--   cover_image) because JOBS_VIA_CAMPAIGNS.sql claims to use "ACTUAL live columns
--   (verified)" and treats them as already-existing (no ADD COLUMN for them).
--   If the live DB has the schema.sql names instead, the Flutter jobs_provider
--   INSERT will fail — see SECTION 0 for the alternative.
--
-- EXECUTION ORDER
--   Run AFTER 01_RLS_FIXES.sql.
--
-- IDEMPOTENCY
--   All ADD COLUMN IF NOT EXISTS. Safe to run multiple times.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 0 — ONLY IF per_creator_payout / total_slots / cover_image_url
--             exist on the live DB and jobs_provider is writing wrong names.
--
-- ⚠️  DO NOT run Section 0 blindly. Run 99_VERIFICATION_QUERIES.sql first
--     to determine which column names actually exist.
--
-- If the live DB has per_creator_payout (schema.sql names), run Section 0
-- to add the aliases so both Flutter screens work:
--
-- ALTER TABLE public.campaigns
--     ADD COLUMN IF NOT EXISTS payout_per_creator NUMERIC(12,2) GENERATED ALWAYS AS (per_creator_payout) STORED;
--
-- NOTE: GENERATED ALWAYS AS is Postgres 12+. An alternative is to keep both
-- as independent columns and keep them in sync via a trigger. Easiest fix is
-- to update jobs_provider.dart to use the schema.sql names once confirmed.
-- ─────────────────────────────────────────────────────────────────────────────


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1 — Campaign creation form extra columns
-- ─────────────────────────────────────────────────────────────────────────────

-- Company name shown on campaign cards
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS company_name TEXT;

-- Target audience gender filter
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS gender TEXT;
-- Safe guard: add constraint only if it doesn't already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'campaigns_gender_check'
    ) THEN
        ALTER TABLE public.campaigns
            ADD CONSTRAINT campaigns_gender_check
            CHECK (gender IN ('all', 'male', 'female'));
    END IF;
END$$;

-- Target page/profile category
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS page_profile_category TEXT;

-- Expand platform CHECK to include 'facebook'
ALTER TABLE public.campaigns DROP CONSTRAINT IF EXISTS campaigns_platform_check;
ALTER TABLE public.campaigns
    ADD CONSTRAINT campaigns_platform_check
    CHECK (platform IN ('instagram', 'youtube', 'tiktok', 'twitter', 'facebook', 'multiple'));


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2 — Job marker column (payout_model = 'job')
-- ─────────────────────────────────────────────────────────────────────────────

-- payout_model is used as the canonical job marker by the Flutter app.
-- This is the EXISTING cached column; we only ensure its values are allowed.
-- NOTE: Do NOT add payout_model as a new column — it should already exist.
-- If it does not exist, run JOBS_VIA_CAMPAIGNS.sql first, then return here.

-- Expand status CHECK to allow 'closed' (used for job status management)
ALTER TABLE public.campaigns DROP CONSTRAINT IF EXISTS campaigns_status_check;
ALTER TABLE public.campaigns
    ADD CONSTRAINT campaigns_status_check
    CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled', 'closed'));


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3 — Rules and demo-asset columns for campaigns and jobs
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS rules text;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS demo_asset_type text;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS demo_asset_url text;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4 — Applications table extensions for job submission workflow
-- ─────────────────────────────────────────────────────────────────────────────

-- Job submission proof fields
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_type    text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_url     text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submission_note    text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS rejection_reason   text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS submitted_at       timestamptz;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS reviewed_at        timestamptz;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS reviewed_by        uuid REFERENCES public.users(id);

-- Campaign applicant profile fields (captured on apply form)
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS applicant_name     text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS location           text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS category           text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS city               text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS state              text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS contact_number     text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS instagram_url      text;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS followers_count    integer;

-- Expand applications status CHECK to include job statuses
ALTER TABLE public.applications DROP CONSTRAINT IF EXISTS applications_status_check;
UPDATE public.applications
SET status = 'pending'
WHERE status IS NULL
   OR status NOT IN ('pending','approved','rejected','withdrawn','applied','submitted');
ALTER TABLE public.applications
    ADD CONSTRAINT applications_status_check
    CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn', 'applied', 'submitted'));


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5 — Job slot enforcement trigger
--   Fires BEFORE INSERT on applications to prevent over-booking job slots.
--   Uses payout_model = 'job' as the job marker (existing cached column).
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.enforce_job_slots()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_model text;
    v_slots integer;
    v_count integer;
BEGIN
    SELECT payout_model, slots
    INTO v_model, v_slots
    FROM public.campaigns
    WHERE id = NEW.campaign_id;

    -- Only enforce for job rows with a finite positive slot cap.
    IF v_model = 'job' AND v_slots IS NOT NULL AND v_slots > 0 THEN
        SELECT count(*) INTO v_count
        FROM public.applications
        WHERE campaign_id = NEW.campaign_id
          AND status IN ('applied', 'submitted', 'approved');
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
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_job_slots();


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6 — Products: product_type column
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS product_type TEXT NOT NULL DEFAULT 'ecommerce';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'products_product_type_check'
    ) THEN
        ALTER TABLE public.products
            ADD CONSTRAINT products_product_type_check
            CHECK (product_type IN ('ecommerce', 'digital'));
    END IF;
END$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 7 — Reload PostgREST schema cache
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
