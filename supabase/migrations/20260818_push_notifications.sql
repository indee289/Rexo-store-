-- Supabase Migration: Push Notification System & Device Management

-- 1. Create user_devices table
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    platform VARCHAR(50) NOT NULL DEFAULT 'android',
    app_version VARCHAR(50) NOT NULL DEFAULT '1.0.0',
    device_name VARCHAR(255) DEFAULT 'Android Mobile',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for user_devices
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_fcm_token ON public.user_devices(fcm_token);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_devices
CREATE POLICY "Users can manage their own devices" 
ON public.user_devices 
FOR ALL USING (auth.uid() = user_id OR (SELECT is_admin(auth.uid())));

-- Service Role / Admin backend bypass for sending notifications
CREATE POLICY "Service role full access to user_devices" 
ON public.user_devices FOR ALL TO service_role USING (true);
