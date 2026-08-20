-- 009_profile_and_security.sql
-- 1. Ensure new fields in creator_profiles
ALTER TABLE creator_profiles 
ADD COLUMN IF NOT EXISTS age INT,
ADD COLUMN IF NOT EXISTS website TEXT;

-- 2. User Sessions Table (Real-time device tracking)
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    device_info TEXT NOT NULL,
    ip_address TEXT,
    last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_current BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'revoked', 'logged_out')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Security Logs Table
CREATE TABLE IF NOT EXISTS public.security_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    ip_address TEXT,
    device_info TEXT,
    status TEXT DEFAULT 'success',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_user_id ON public.security_logs(user_id);

-- Enable RLS
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_logs ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users view own sessions" ON public.user_sessions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users update own sessions" ON public.user_sessions FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users view own security logs" ON public.security_logs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users insert own security logs" ON public.security_logs FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins view all security logs" ON public.security_logs FOR SELECT USING (is_admin(auth.uid()));
