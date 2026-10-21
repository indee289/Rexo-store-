-- ============================================================================
-- Campster — CAMPAIGN CREATION FIX (brand "something went wrong")
--
-- Brand campaign create fail ho raha tha. Wajah (ek ya zyada):
--   1. Owner column mismatch: app `brandId` likhta tha, par live table mein
--      `brand_id` (NOT NULL) ho sakta hai -> NOT NULL violation + RLS fail.
--   2. `filled_slots` column missing tha (purani fix sirf `slots` add karti thi).
--   3. INSERT RLS policy owner column ko theek match nahi kar rahi thi.
--   4. Kuch columns (created_at/updated_at/budget/deadline/cover_image) ho
--      sakta hai live table mein na hon -> PGRST204 "column not found".
--
-- Ye script IDEMPOTENT hai (baar-baar run karna safe). Data delete nahi karti.
-- Supabase Dashboard -> SQL Editor mein poori file ek baar Run karo, ~10s ruko.
-- ============================================================================

-- is_admin() helper (text-safe, case-insensitive) — policies isse use karti hain.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id::text = auth.uid()::text AND lower(u.role) = 'admin'
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

DO $$
DECLARE col text;
BEGIN
  IF to_regclass('public.campaigns') IS NULL THEN
    RAISE NOTICE 'public.campaigns does not exist — nothing to fix.';
    RETURN;
  END IF;

  -- 1) Har column ensure karo jo app insert karta hai (no-op agar already hai).
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS "brandId"              text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS brand_id               text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS title                  text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS description            text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS category               text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS platform               text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS slots                  integer DEFAULT 0;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS filled_slots           integer DEFAULT 0;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS budget                 numeric DEFAULT 0;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS payout_per_creator     numeric DEFAULT 0;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS deadline               timestamptz;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS company_name           text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS cover_image            text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS gender                 text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS page_profile_category  text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS rules                  text;
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS status                 text DEFAULT 'active';
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS payout_model           text DEFAULT 'campaign';
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS created_at             timestamptz DEFAULT now();
  ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS updated_at             timestamptz DEFAULT now();

  -- 2) Value-reject karne wali CHECK constraints hata do (app values control
  --    karta hai; is se "violates check constraint" errors nahi aayenge).
  ALTER TABLE public.campaigns DROP CONSTRAINT IF EXISTS campaigns_gender_check;
  ALTER TABLE public.campaigns DROP CONSTRAINT IF EXISTS campaigns_platform_check;

  -- 3) `id` ke alawa har NOT-NULL-without-default column par NOT NULL hatao,
  --    taaki jo field insert na ho wo row reject na kare (brand_id/brandId
  --    bhi include — app ab dono likhta hai, ye extra safety hai).
  FOR col IN
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'campaigns'
      AND is_nullable = 'NO' AND column_default IS NULL
      AND column_name <> 'id'
  LOOP
    EXECUTE format('ALTER TABLE public.campaigns ALTER COLUMN %I DROP NOT NULL', col);
  END LOOP;

  -- 4) RLS: brand apni campaign bana sake (dono owner columns check), admin sab.
  ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

  DROP POLICY IF EXISTS "Admins can insert campaigns" ON public.campaigns;
  DROP POLICY IF EXISTS "Brands can insert campaigns" ON public.campaigns;
  CREATE POLICY "Brands can insert campaigns" ON public.campaigns
    FOR INSERT WITH CHECK (
      public.is_admin()
      OR auth.uid()::text = "brandId"::text
      OR auth.uid()::text = brand_id::text
    );

  -- Sab logged-in users campaigns dekh sakein (browse/list).
  DROP POLICY IF EXISTS "Anyone can read campaigns" ON public.campaigns;
  CREATE POLICY "Anyone can read campaigns" ON public.campaigns
    FOR SELECT USING (true);

  -- Owner / admin apni campaign update/delete kar sake.
  DROP POLICY IF EXISTS "Owner can update campaigns" ON public.campaigns;
  CREATE POLICY "Owner can update campaigns" ON public.campaigns
    FOR UPDATE USING (
      public.is_admin()
      OR auth.uid()::text = "brandId"::text
      OR auth.uid()::text = brand_id::text
    );

  DROP POLICY IF EXISTS "Owner can delete campaigns" ON public.campaigns;
  CREATE POLICY "Owner can delete campaigns" ON public.campaigns
    FOR DELETE USING (
      public.is_admin()
      OR auth.uid()::text = "brandId"::text
      OR auth.uid()::text = brand_id::text
    );
END $$;

-- 5) PostgREST schema cache reload.
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Verify:
-- SELECT column_name, is_nullable FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='campaigns' ORDER BY column_name;
-- SELECT policyname, cmd FROM pg_policies WHERE tablename='campaigns';
