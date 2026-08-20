-- 1. Drop existing conflicting snake_case tables
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS subscription_plans CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS kyc_documents CASCADE;
DROP TABLE IF EXISTS user_devices CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS disputes CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS deposits CASCADE;
DROP TABLE IF EXISTS withdrawals CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;

-- 2. Wallets & Transactions
CREATE TABLE wallets (
    "userId" TEXT PRIMARY KEY,
    "availableBalance" NUMERIC DEFAULT 0,
    "pendingBalance" NUMERIC DEFAULT 0,
    "totalEarned" NUMERIC DEFAULT 0,
    "totalSpent" NUMERIC DEFAULT 0,
    "escrowHold" NUMERIC DEFAULT 0,
    "isFrozen" BOOLEAN DEFAULT false
);

CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    "userId" TEXT,
    type TEXT,
    amount NUMERIC,
    direction TEXT,
    status TEXT,
    note TEXT,
    "referenceId" TEXT,
    "campaignId" TEXT,
    "campaignTitle" TEXT,
    date TEXT
);

-- 3. Deposits & Withdrawals
CREATE TABLE deposits (
    id TEXT PRIMARY KEY,
    "brandId" TEXT,
    "brandName" TEXT,
    amount NUMERIC,
    "paymentMethod" TEXT,
    "transactionRef" TEXT,
    "proofScreenshotUrl" TEXT,
    notes TEXT,
    status TEXT,
    "createdAt" TEXT,
    "processedAt" TEXT,
    "adminNotes" TEXT
);

CREATE TABLE withdrawals (
    id TEXT PRIMARY KEY,
    "userId" TEXT,
    "userName" TEXT,
    "userRole" TEXT,
    amount NUMERIC,
    method TEXT,
    "payoutDetails" JSONB,
    status TEXT,
    "createdAt" TEXT,
    "processedAt" TEXT,
    "transactionRef" TEXT,
    "adminNotes" TEXT
);

-- 4. Admin Logs & Disputes
CREATE TABLE disputes (
    id TEXT PRIMARY KEY,
    "reporterId" TEXT,
    "reporterName" TEXT,
    "targetId" TEXT,
    "targetType" TEXT,
    "targetTitle" TEXT,
    "reasonType" TEXT,
    description TEXT,
    status TEXT,
    "adminNotes" TEXT,
    "createdAt" TEXT,
    "updatedAt" TEXT
);

CREATE TABLE audit_logs (
    id TEXT PRIMARY KEY,
    "adminId" TEXT,
    "adminName" TEXT,
    "adminRole" TEXT,
    action TEXT,
    "targetType" TEXT,
    "targetId" TEXT,
    "targetName" TEXT,
    reason TEXT,
    "ipAddress" TEXT,
    timestamp TEXT
);

-- 5. Notifications & Devices
CREATE TABLE notifications (
    id TEXT PRIMARY KEY,
    "userId" TEXT,
    title TEXT,
    body TEXT,
    message TEXT,
    type TEXT,
    payload JSONB,
    "isRead" BOOLEAN DEFAULT false,
    "createdAt" TEXT
);

CREATE TABLE user_devices (
    id TEXT PRIMARY KEY,
    "userId" TEXT,
    "fcmToken" TEXT,
    platform TEXT,
    "appVersion" TEXT,
    "deviceName" TEXT,
    "createdAt" TEXT,
    "updatedAt" TEXT
);

-- 6. KYC & Settings
CREATE TABLE kyc_documents (
    id TEXT PRIMARY KEY,
    "userId" TEXT,
    "userName" TEXT,
    "documentType" TEXT,
    "documentNumber" TEXT,
    "documentUrl" TEXT,
    status TEXT,
    "submittedAt" TEXT,
    "verifiedAt" TEXT,
    "rejectionReason" TEXT,
    "adminNotes" TEXT
);

CREATE TABLE user_settings (
    "userId" TEXT PRIMARY KEY,
    username TEXT,
    "twoFactorAuth" BOOLEAN,
    "biometricAuth" BOOLEAN,
    "pushNotifications" BOOLEAN,
    "emailNotifications" BOOLEAN,
    "payoutUpi" TEXT,
    "payoutBank" TEXT,
    "profileVisibility" TEXT,
    currency TEXT,
    language TEXT
);

CREATE TABLE system_settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    "platformCommissionRate" NUMERIC,
    "escrowFeePercent" NUMERIC,
    "minimumWithdrawalAmount" NUMERIC,
    "maximumWithdrawalAmount" NUMERIC,
    "kycRequiredForPayout" BOOLEAN,
    "autoApproveVerifiedCreators" BOOLEAN,
    "maintenanceMode" BOOLEAN,
    "featureFlags" JSONB
);

-- Insert default system settings
INSERT INTO system_settings (id, "platformCommissionRate", "escrowFeePercent", "minimumWithdrawalAmount", "maximumWithdrawalAmount", "kycRequiredForPayout", "autoApproveVerifiedCreators", "maintenanceMode", "featureFlags")
VALUES (
    'default', 
    0.10, 
    0.02, 
    1000, 
    100000, 
    true, 
    false, 
    false, 
    '{"enableCryptoPayouts": false, "enableInstantPayouts": false, "enableAiMatching": false}'
);

-- 7. Subscriptions
CREATE TABLE subscription_plans (
    id TEXT PRIMARY KEY,
    name TEXT,
    price NUMERIC,
    duration TEXT,
    features JSONB,
    status TEXT
);

CREATE TABLE user_subscriptions (
    id TEXT PRIMARY KEY,
    "userId" TEXT,
    "planId" TEXT,
    "planName" TEXT,
    "startDate" TEXT,
    "expiryDate" TEXT,
    status TEXT
);

-- NEUTRALIZED FOR SECURITY: RLS should never be off. See 020_restore_secure_rls.sql
-- (You can enable them later when you add strict Auth rules)
