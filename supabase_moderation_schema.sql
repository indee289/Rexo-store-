-- ========================================================================================
-- REXO STORE: ENTERPRISE TRUST & SAFETY, AI MODERATION, AND ANTI-CHEAT SCHEMA
-- ========================================================================================

-- 1. EXTEND EXISTING USERS TABLE
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS risk_score INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS trust_score INT DEFAULT 100,
ADD COLUMN IF NOT EXISTS warning_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS account_status VARCHAR(50) DEFAULT 'active', -- active, warned, restricted, suspended, shadow_banned, banned
ADD COLUMN IF NOT EXISTS last_risk_update TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS is_shadow_banned BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS suspension_end_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS device_hash VARCHAR(255),
ADD COLUMN IF NOT EXISTS last_ip_hash VARCHAR(255),
ADD COLUMN IF NOT EXISTS last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_account_status ON users(account_status);
CREATE INDEX IF NOT EXISTS idx_users_device_hash ON users(device_hash);
CREATE INDEX IF NOT EXISTS idx_users_risk_score ON users(risk_score);

-- 2. MODERATION QUEUE (For Admin Review)
CREATE TABLE IF NOT EXISTS moderation_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_type VARCHAR(50) NOT NULL, -- user, campaign, product, message, review
    target_id UUID NOT NULL,
    reporter_id UUID, -- NULL if AI flagged
    ai_risk_score INT,
    ai_confidence INT,
    ai_category VARCHAR(100),
    ai_reason TEXT,
    recommended_action VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending', -- pending, reviewed_approved, reviewed_rejected, action_taken
    admin_id UUID, -- Admin who reviewed it
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_mod_queue_status ON moderation_queue(status);

-- 3. DEVICE FINGERPRINTS & LINKED ACCOUNTS
CREATE TABLE IF NOT EXISTS device_fingerprints (
    device_hash VARCHAR(255) PRIMARY KEY,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    device_type VARCHAR(100),
    platform VARCHAR(100),
    app_version VARCHAR(50),
    risk_score INT DEFAULT 0,
    is_blacklisted BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS linked_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    device_hash VARCHAR(255) REFERENCES device_fingerprints(device_hash) ON DELETE CASCADE,
    linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, device_hash)
);

-- 4. USER WARNINGS & SUSPENSIONS LOG
CREATE TABLE IF NOT EXISTS user_warnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    admin_id UUID,
    reason TEXT NOT NULL,
    evidence TEXT,
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_suspensions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    admin_id UUID,
    reason TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'active' -- active, appealed, lifted, expired
);

-- 5. AI MODERATION LOGS & AUDIT SYSTEM
CREATE TABLE IF NOT EXISTS ai_moderation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_type VARCHAR(50),
    content_id UUID,
    analyzed_text TEXT,
    risk_score INT,
    category VARCHAR(100),
    decision VARCHAR(50), -- safe, flagged, shadow_banned
    latency_ms INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS security_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action VARCHAR(100) NOT NULL, -- login, ban, warn, withdraw_approve
    actor_id UUID NOT NULL, -- User or Admin who did it
    target_id UUID, -- Affected user/entity
    ip_hash VARCHAR(255),
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================================================================
-- RLS (ROW LEVEL SECURITY) POLICIES FOR SHADOW BAN ENFORCEMENT
-- ========================================================================================

-- Extend campaigns to support AI flags
ALTER TABLE campaigns 
ADD COLUMN IF NOT EXISTS ai_flag_status VARCHAR(50) DEFAULT 'safe', -- safe, flagged, pending_review
ADD COLUMN IF NOT EXISTS moderation_reason TEXT;

-- Drop existing public read policies if they exist (Replace with actual policy names from your DB)
-- DROP POLICY IF EXISTS "Public campaigns are viewable by everyone." ON campaigns;

-- NEW SHADOW BAN AWARE CAMPAIGN RLS POLICY
-- A campaign is visible if:
-- 1. The viewer is an admin (role = 'admin')
-- 2. The viewer is the owner (auth.uid() = brand_id)
-- 3. The campaign is active, AND the owner is NOT shadow_banned, AND the campaign is NOT pending_review
CREATE POLICY "Shadow Ban Aware Campaign Visibility" ON campaigns
FOR SELECT
USING (
    (auth.jwt()->>'role' = 'admin') OR
    (auth.uid() = brand_id) OR
    (
        status = 'active' AND 
        ai_flag_status != 'pending_review' AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = campaigns.brand_id 
            AND users.account_status != 'shadow_banned'
            AND users.account_status != 'banned'
        )
    )
);

-- SHADOW BAN AWARE MESSAGES (CHAT) RLS POLICY
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_hidden_by_ai BOOLEAN DEFAULT false;

CREATE POLICY "Shadow Ban Aware Message Visibility" ON messages
FOR SELECT
USING (
    (auth.jwt()->>'role' = 'admin') OR
    (auth.uid() = sender_id) OR
    (
        is_hidden_by_ai = false AND
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = messages.sender_id 
            AND users.account_status != 'shadow_banned'
        )
    )
);

-- ========================================================================================
-- DATABASE TRIGGERS FOR AUTO-AUDITING
-- ========================================================================================
-- Create a function to automatically log admin actions
CREATE OR REPLACE FUNCTION log_admin_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.account_status IS DISTINCT FROM NEW.account_status THEN
        INSERT INTO security_audit_logs (action, actor_id, target_id, details)
        VALUES (
            'STATUS_CHANGE_' || UPPER(NEW.account_status),
            auth.uid(), -- Assuming admin is making the change
            NEW.id,
            jsonb_build_object('old_status', OLD.account_status, 'new_status', NEW.account_status)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_admin_status_change ON users;
CREATE TRIGGER trigger_admin_status_change
AFTER UPDATE OF account_status ON users
FOR EACH ROW
EXECUTE FUNCTION log_admin_status_change();
