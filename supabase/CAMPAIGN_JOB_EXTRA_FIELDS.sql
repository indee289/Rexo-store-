-- ============================================================================
-- CAMPAIGN_JOB_EXTRA_FIELDS.sql
-- Adds the extra fields captured by the Campaign create/edit form and the
-- Post a Job form: optional campaign/job rules and an optional demo asset.
-- (The `platform` and `description` columns ALREADY EXIST on public.campaigns
--  and are intentionally NOT touched here.)
-- ============================================================================
--
-- HOW TO USE THIS FILE
-- --------------------
-- 1. Open the Supabase Dashboard, then open the SQL Editor.
-- 2. Copy the WHOLE file and click Run once. It is idempotent and safe to run
--    as many times as you like -- every ADD COLUMN uses IF NOT EXISTS so a
--    re-run never errors and never overwrites existing data.
-- 3. Wait about 10 seconds so PostgREST can reload its schema cache before you
--    use the app.
--
-- WHAT IT ADDS
-- ------------
-- Jobs and campaigns are both stored as rows in the legacy public.campaigns
-- table (jobs are tagged payout_model = 'job'). These three columns back the
-- new optional inputs on both forms:
--   * rules            text -- free-text rules / guidelines (optional).
--   * demo_asset_type  text -- one of: image | video | pdf | link | text.
--   * demo_asset_url   text -- meaning depends on demo_asset_type:
--                              - image / video / pdf : the Cloudflare R2 URL
--                                of the uploaded file,
--                              - link                : the pasted external URL,
--                              - text                : the raw text body.
--
-- The Flutter app WRITES these as plain insert/update values and READS them
-- back from a SELECT * result map by key. It never names them in a .select()
-- projection or a server-side filter, so the PostgREST schema cache serves
-- them without a PGRST205/PGRST204/42703 error.
-- ============================================================================


-- ============================================================================
-- SECTION A - ADD the new optional columns (idempotent).
-- ============================================================================
ALTER TABLE public.campaigns
    ADD COLUMN IF NOT EXISTS rules text;

ALTER TABLE public.campaigns
    ADD COLUMN IF NOT EXISTS demo_asset_type text;

ALTER TABLE public.campaigns
    ADD COLUMN IF NOT EXISTS demo_asset_url text;


-- ============================================================================
-- SECTION B - RELOAD POSTGREST
-- ----------------------------------------------------------------------------
-- Tell PostgREST to reload its schema cache and configuration so the new
-- columns are available immediately.
-- ============================================================================
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
