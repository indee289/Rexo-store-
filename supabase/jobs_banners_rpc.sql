-- =============================================================================
-- Jobs / Job Applications / Banners RPC Functions
-- =============================================================================
-- WHY THIS FILE EXISTS:
-- PostgREST returns PGRST205 ("Could not find the table ... in the schema
-- cache") when the Dart client accesses public.jobs / public.job_applications /
-- public.banners directly via `.from(...)`. To work around the stale
-- schema-cache issue, ALL reads and writes for these three tables now go
-- through SECURITY DEFINER RPC functions defined below. The Dart providers call
-- these via `.rpc(...)` instead of `.from(...)`.
--
-- CONVENTIONS:
--   * Every function is SECURITY DEFINER + SET search_path = public so it runs
--     with the definer's privileges but a fixed, safe search path.
--   * Authorization is enforced INSIDE each function body:
--       - Admin-only functions call public.is_admin() (already deployed — see
--         supabase/PERMANENT_FIX_run_this.sql — do NOT redefine it here).
--       - Ownership checks compare auth.uid()::text with user_id::text, matching
--         the existing RLS policies (both sides cast to text).
--   * Every function has a matching GRANT EXECUTE ... TO authenticated. The
--     internal checks (is_admin / ownership) still gate access, mirroring the
--     wallet RPC pattern.
--   * The enforce_job_slots BEFORE INSERT trigger on job_applications still runs
--     because apply_to_job performs a real INSERT into the table.
--
-- DEPLOY: run this whole file once in the Supabase SQL Editor. The final
--         NOTIFY pgrst, 'reload schema'; forces PostgREST to reload.
-- =============================================================================

-- ─── READ FUNCTIONS ──────────────────────────────────────────────────────────

-- Active jobs feed for the Available Jobs tab. Optional category + search.
CREATE OR REPLACE FUNCTION public.get_active_jobs(
  p_category text DEFAULT NULL,
  p_search text DEFAULT NULL
)
RETURNS SETOF public.jobs
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT *
  FROM public.jobs
  WHERE status = 'active'
    AND (p_category IS NULL OR category = p_category)
    AND (p_search IS NULL OR title ILIKE '%' || p_search || '%')
  ORDER BY created_at DESC
  LIMIT 100;
$$;
GRANT EXECUTE ON FUNCTION public.get_active_jobs(text, text) TO authenticated;

-- All jobs (admin manage list). Admin-only.
CREATE OR REPLACE FUNCTION public.get_jobs()
RETURNS SETOF public.jobs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.jobs
  ORDER BY created_at DESC
  LIMIT 200;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_jobs() TO authenticated;

-- Single job by id. Visible if active, or to admins for any status.
CREATE OR REPLACE FUNCTION public.get_job_by_id(p_job_id uuid)
RETURNS SETOF public.jobs
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT *
  FROM public.jobs
  WHERE id = p_job_id
    AND (status = 'active' OR public.is_admin());
$$;
GRANT EXECUTE ON FUNCTION public.get_job_by_id(uuid) TO authenticated;

-- A user's job applications. Owner or admin only.
CREATE OR REPLACE FUNCTION public.get_job_applications(p_user_id text)
RETURNS SETOF public.job_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid()::text <> p_user_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.job_applications
  WHERE user_id::text = p_user_id
  ORDER BY applied_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_job_applications(text) TO authenticated;

-- All submitted (pending review) applications. Admin-only.
CREATE OR REPLACE FUNCTION public.get_submitted_applications()
RETURNS SETOF public.job_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.job_applications
  WHERE status = 'submitted'
  ORDER BY submitted_at DESC
  LIMIT 200;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_submitted_applications() TO authenticated;

-- Total applicant count for a job (admin list). Admin-only.
CREATE OR REPLACE FUNCTION public.get_job_applicant_count(p_job_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.job_applications
  WHERE job_id = p_job_id;

  RETURN v_count;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_job_applicant_count(uuid) TO authenticated;

-- Filled-slot count for a job (applied/submitted/approved).
CREATE OR REPLACE FUNCTION public.get_job_slot_count(p_job_id uuid)
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT count(*)::integer
  FROM public.job_applications
  WHERE job_id = p_job_id
    AND status IN ('applied', 'submitted', 'approved');
$$;
GRANT EXECUTE ON FUNCTION public.get_job_slot_count(uuid) TO authenticated;

-- Whether a user already applied to a job. Owner or admin only: without this
-- guard any authenticated caller could probe another user's application state
-- for an arbitrary (job_id, user_id) pair (an application-membership oracle).
-- The Dart caller passes the current user's own id, so normal use is unaffected.
CREATE OR REPLACE FUNCTION public.has_applied_to_job(
  p_job_id uuid,
  p_user_id text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid()::text <> p_user_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.job_applications
    WHERE job_id = p_job_id
      AND user_id::text = p_user_id
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.has_applied_to_job(uuid, text) TO authenticated;

-- Visible banners for the home carousel.
CREATE OR REPLACE FUNCTION public.get_banners()
RETURNS SETOF public.banners
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT *
  FROM public.banners
  WHERE is_visible = true
  ORDER BY sort_order ASC;
$$;
GRANT EXECUTE ON FUNCTION public.get_banners() TO authenticated;

-- All banners (including hidden). Admin-only.
CREATE OR REPLACE FUNCTION public.get_all_banners()
RETURNS SETOF public.banners
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.banners
  ORDER BY sort_order ASC;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_all_banners() TO authenticated;

-- ─── WRITE FUNCTIONS ─────────────────────────────────────────────────────────

-- Apply to a job as the current user. Goes through a real INSERT so the
-- enforce_job_slots BEFORE INSERT trigger still fires.
CREATE OR REPLACE FUNCTION public.apply_to_job(p_job_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.job_applications (job_id, user_id, status, applied_at)
  VALUES (p_job_id, auth.uid(), 'applied', now())
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.apply_to_job(uuid) TO authenticated;

-- Submit proof for an applied job (owner only).
CREATE OR REPLACE FUNCTION public.submit_job_task(
  p_application_id uuid,
  p_submission_type text,
  p_submission_url text,
  p_submission_note text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id text;
BEGIN
  SELECT user_id::text INTO v_user_id
  FROM public.job_applications
  WHERE id = p_application_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Application not found';
  END IF;

  IF v_user_id <> auth.uid()::text THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE public.job_applications
  SET status = 'submitted',
      submission_type = p_submission_type,
      submission_url = p_submission_url,
      submission_note = p_submission_note,
      submitted_at = now()
  WHERE id = p_application_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.submit_job_task(uuid, text, text, text) TO authenticated;

-- Create a new job (admin-only). created_by/status/timestamps set here.
CREATE OR REPLACE FUNCTION public.create_job(p_data jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  INSERT INTO public.jobs (
    title, description, category, payment_amount, max_slots, deadline,
    cover_image_url, status, created_by, created_at, updated_at
  )
  VALUES (
    p_data->>'title',
    p_data->>'description',
    p_data->>'category',
    (p_data->>'payment_amount')::numeric,
    CASE WHEN p_data ? 'max_slots' AND p_data->>'max_slots' IS NOT NULL
         THEN (p_data->>'max_slots')::integer ELSE NULL END,
    CASE WHEN p_data ? 'deadline' AND p_data->>'deadline' IS NOT NULL
         THEN (p_data->>'deadline')::timestamptz ELSE NULL END,
    p_data->>'cover_image_url',
    'active',
    auth.uid(),
    now(),
    now()
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.create_job(jsonb) TO authenticated;

-- Update a job (admin-only). Only keys present in p_data are changed.
CREATE OR REPLACE FUNCTION public.update_job(p_job_id uuid, p_data jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  -- NOTE ON NULL SEMANTICS: this mirrors the old `.update({...data})` write.
  -- Nullable text columns the edit form can blank (category, cover_image_url)
  -- use the present-key CASE form: when the key is present with a null value
  -- the column is cleared to NULL; when the key is absent the column is left
  -- untouched. NOT NULL columns (title, description, status) keep COALESCE so a
  -- missing/null key preserves the existing value and never violates NOT NULL
  -- (the post-job form always sends title/description as non-empty text).
  UPDATE public.jobs
  SET title = COALESCE(p_data->>'title', title),
      description = COALESCE(p_data->>'description', description),
      category = CASE WHEN p_data ? 'category'
                      THEN p_data->>'category' ELSE category END,
      payment_amount = COALESCE((p_data->>'payment_amount')::numeric, payment_amount),
      max_slots = CASE WHEN p_data ? 'max_slots'
                       THEN (p_data->>'max_slots')::integer ELSE max_slots END,
      deadline = CASE WHEN p_data ? 'deadline'
                      THEN (p_data->>'deadline')::timestamptz ELSE deadline END,
      cover_image_url = CASE WHEN p_data ? 'cover_image_url'
                             THEN p_data->>'cover_image_url' ELSE cover_image_url END,
      status = COALESCE(p_data->>'status', status),
      updated_at = now()
  WHERE id = p_job_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.update_job(uuid, jsonb) TO authenticated;

-- Delete a job (admin-only). Cascades to job_applications.
CREATE OR REPLACE FUNCTION public.delete_job(p_job_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  DELETE FROM public.jobs WHERE id = p_job_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.delete_job(uuid) TO authenticated;

-- Fetch the core ids of an application (admin-only). Used by approve/reject.
CREATE OR REPLACE FUNCTION public.get_application_core(p_application_id uuid)
RETURNS TABLE(user_id text, job_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  RETURN QUERY
  SELECT ja.user_id::text, ja.job_id
  FROM public.job_applications ja
  WHERE ja.id = p_application_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_application_core(uuid) TO authenticated;

-- Update an application's review status (admin-only).
CREATE OR REPLACE FUNCTION public.update_application_status(
  p_application_id uuid,
  p_status text,
  p_rejection_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  UPDATE public.job_applications
  SET status = p_status,
      rejection_reason = COALESCE(p_rejection_reason, rejection_reason),
      reviewed_at = now(),
      reviewed_by = auth.uid()
  WHERE id = p_application_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.update_application_status(uuid, text, text) TO authenticated;

-- Create a banner (admin-only). created_by/timestamps set here.
CREATE OR REPLACE FUNCTION public.create_banner(p_data jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  INSERT INTO public.banners (
    title, image_url, link_type, link_campaign_id, link_page,
    is_visible, sort_order, created_by, created_at, updated_at
  )
  VALUES (
    p_data->>'title',
    p_data->>'image_url',
    COALESCE(p_data->>'link_type', 'none'),
    CASE WHEN p_data ? 'link_campaign_id' AND p_data->>'link_campaign_id' IS NOT NULL
         THEN (p_data->>'link_campaign_id')::uuid ELSE NULL END,
    p_data->>'link_page',
    COALESCE((p_data->>'is_visible')::boolean, true),
    COALESCE((p_data->>'sort_order')::integer, 0),
    auth.uid(),
    now(),
    now()
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.create_banner(jsonb) TO authenticated;

-- Update a banner (admin-only). Only keys present in p_data are changed.
CREATE OR REPLACE FUNCTION public.update_banner(p_id uuid, p_data jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  -- NOTE ON NULL SEMANTICS: this mirrors the old `.update({...data})` write.
  -- Nullable text columns the edit form can blank (title, link_page) use the
  -- present-key CASE form so a present-with-null key clears the column and an
  -- absent key leaves it untouched. link_campaign_id already uses this form, so
  -- switching a banner between page/campaign link types now clears the stale
  -- sibling column consistently. image_url is NOT NULL, so it keeps COALESCE and
  -- can never be nulled. link_type has a CHECK constraint and is always sent by
  -- the form, so COALESCE (which preserves on a missing key) is sufficient.
  UPDATE public.banners
  SET title = CASE WHEN p_data ? 'title'
                   THEN p_data->>'title' ELSE title END,
      image_url = COALESCE(p_data->>'image_url', image_url),
      link_type = COALESCE(p_data->>'link_type', link_type),
      link_campaign_id = CASE WHEN p_data ? 'link_campaign_id'
                              THEN (p_data->>'link_campaign_id')::uuid
                              ELSE link_campaign_id END,
      link_page = CASE WHEN p_data ? 'link_page'
                       THEN p_data->>'link_page' ELSE link_page END,
      is_visible = COALESCE((p_data->>'is_visible')::boolean, is_visible),
      sort_order = COALESCE((p_data->>'sort_order')::integer, sort_order),
      updated_at = now()
  WHERE id = p_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.update_banner(uuid, jsonb) TO authenticated;

-- Delete a banner (admin-only).
CREATE OR REPLACE FUNCTION public.delete_banner(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  DELETE FROM public.banners WHERE id = p_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.delete_banner(uuid) TO authenticated;

-- ─── FORCE POSTGREST TO RELOAD ───────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';
