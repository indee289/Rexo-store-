-- ============================================================================
-- Jobs / Job Applications / Banners — rebuilt EXACTLY like the campaigns table
-- (which works perfectly). Same style: no "public." prefix, no IF NOT EXISTS,
-- inline admin check (no is_admin() helper), uuid user columns, simple RLS.
--
-- This is the permanent fix. Run the WHOLE script once in Supabase SQL Editor.
-- It drops and recreates the 3 tables cleanly, so any half-broken previous
-- state is wiped. (Existing job/banner rows will be removed — re-post them.)
-- ============================================================================

-- Drop old objects (functions + tables) so we start clean.
DROP TABLE IF EXISTS job_applications CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS banners CASCADE;

-- ─── JOBS TABLE (mirrors campaigns style) ────────────────────────────────────
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT,
    payment_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    max_slots INTEGER,
    deadline TIMESTAMPTZ,
    cover_image_url TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','closed','draft')),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── JOB APPLICATIONS TABLE (user_id is UUID, like campaigns.brand_id) ───────
CREATE TABLE job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'applied' CHECK (status IN ('applied','submitted','approved','rejected')),
    submission_type TEXT CHECK (submission_type IN ('link','photo','pdf','video')),
    submission_url TEXT,
    submission_note TEXT,
    rejection_reason TEXT,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES users(id),
    UNIQUE (job_id, user_id)
);

-- ─── BANNERS TABLE ───────────────────────────────────────────────────────────
CREATE TABLE banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT,
    image_url TEXT NOT NULL,
    link_type TEXT CHECK (link_type IN ('none','campaign','page')),
    link_campaign_id UUID REFERENCES campaigns(id) ON DELETE SET NULL,
    link_page TEXT,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── ENABLE RLS ──────────────────────────────────────────────────────────────
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- ─── JOBS POLICIES (copied from campaigns pattern) ───────────────────────────
CREATE POLICY "Anyone can read active jobs" ON jobs
    FOR SELECT USING (status = 'active' OR created_by = auth.uid() OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can create jobs" ON jobs
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can update jobs" ON jobs
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can delete jobs" ON jobs
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- ─── JOB APPLICATIONS POLICIES (copied from applications pattern) ────────────
CREATE POLICY "Users can read own applications" ON job_applications
    FOR SELECT USING (auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can create own applications" ON job_applications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own applications" ON job_applications
    FOR UPDATE USING (
        (auth.uid() = user_id AND status = 'applied') OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can delete applications" ON job_applications
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- ─── BANNERS POLICIES ────────────────────────────────────────────────────────
CREATE POLICY "Anyone can read visible banners" ON banners
    FOR SELECT USING (is_visible = TRUE OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can create banners" ON banners
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can update banners" ON banners
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Admins can delete banners" ON banners
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    );

-- ─── SLOT ENFORCEMENT TRIGGER ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION check_job_slots()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_max_slots integer;
  v_count     integer;
BEGIN
  SELECT max_slots INTO v_max_slots FROM jobs WHERE id = NEW.job_id;
  IF v_max_slots IS NOT NULL THEN
    SELECT COUNT(*) INTO v_count FROM job_applications
    WHERE job_id = NEW.job_id AND status IN ('applied','submitted','approved');
    IF v_count >= v_max_slots THEN
      RAISE EXCEPTION 'This job has no slots remaining.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_job_slots ON job_applications;
CREATE TRIGGER enforce_job_slots
  BEFORE INSERT ON job_applications
  FOR EACH ROW EXECUTE FUNCTION check_job_slots();

-- ─── INDEXES ─────────────────────────────────────────────────────────────────
CREATE INDEX jobs_status_idx ON jobs(status);
CREATE INDEX jobs_category_idx ON jobs(category);
CREATE INDEX job_applications_user_id_idx ON job_applications(user_id);
CREATE INDEX job_applications_job_id_idx ON job_applications(job_id);
CREATE INDEX banners_visible_idx ON banners(is_visible);

-- ─── FORCE POSTGREST RELOAD ──────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';

-- After running: if it still shows "not found", do Settings -> General ->
-- Restart project (guaranteed cache refresh). Then re-post a job/banner.
