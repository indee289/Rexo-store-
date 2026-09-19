-- ============================================================
-- Banners Table Migration
-- Run this in Supabase SQL Editor
-- ============================================================

CREATE TABLE IF NOT EXISTS public.banners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text,
  image_url text NOT NULL,
  link_type text CHECK (link_type IN ('none', 'campaign', 'page')),
  link_campaign_id uuid REFERENCES public.campaigns(id) ON DELETE SET NULL,
  link_page text,
  is_visible boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Everyone can view visible banners" ON public.banners;
DROP POLICY IF EXISTS "Admins manage all banners" ON public.banners;

CREATE POLICY "Everyone can view visible banners"
  ON public.banners FOR SELECT
  USING (is_visible = true OR public.is_admin());

CREATE POLICY "Admins manage all banners"
  ON public.banners FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.update_banners_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS set_banners_updated_at ON public.banners;
CREATE TRIGGER set_banners_updated_at
  BEFORE UPDATE ON public.banners
  FOR EACH ROW EXECUTE FUNCTION public.update_banners_updated_at();

CREATE INDEX IF NOT EXISTS banners_visible_idx ON public.banners(is_visible);
CREATE INDEX IF NOT EXISTS banners_sort_idx ON public.banners(sort_order);
