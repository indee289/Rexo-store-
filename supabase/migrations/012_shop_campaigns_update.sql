-- 1. Drop existing tables that conflict with the frontend data structures
DROP TABLE IF EXISTS digital_downloads CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;
DROP TABLE IF EXISTS deliverables CASCADE;
DROP TABLE IF EXISTS campaign_applications CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;

-- 2. Create new tables that exactly match the frontend JSON structures
CREATE TABLE campaigns (
    id TEXT PRIMARY KEY,
    "brandId" TEXT,
    "brandName" TEXT,
    "brandLogo" TEXT,
    title TEXT,
    description TEXT,
    niche TEXT,
    platform TEXT,
    "deliverableType" TEXT,
    "payoutPerCreator" NUMERIC,
    "totalBudget" NUMERIC,
    "totalSlots" INT,
    "filledSlots" INT,
    "minFollowers" INT,
    "minEngagementRate" NUMERIC,
    deadline TEXT,
    requirements JSONB,
    status TEXT,
    "createdAt" TEXT,
    "escrowStatus" TEXT,
    "escrowAmount" NUMERIC
);

CREATE TABLE campaign_applications (
    id TEXT PRIMARY KEY,
    "campaignId" TEXT REFERENCES campaigns(id) ON DELETE CASCADE,
    "campaignTitle" TEXT,
    "brandName" TEXT,
    "creatorId" TEXT,
    "creatorName" TEXT,
    "creatorAvatar" TEXT,
    "creatorHandle" TEXT,
    "followersCount" INT,
    "engagementRate" NUMERIC,
    "proposedPitch" TEXT,
    "feeRequested" NUMERIC,
    "deliverableUrl" TEXT,
    status TEXT,
    "appliedAt" TEXT,
    "submittedAt" TEXT,
    "reviewedAt" TEXT,
    "rejectionReason" TEXT,
    "payoutRemarks" TEXT,
    "paidAt" TEXT
);

CREATE TABLE products (
    id TEXT PRIMARY KEY,
    title TEXT,
    "productType" TEXT,
    category TEXT,
    "shortDescription" TEXT,
    "fullDescription" TEXT,
    "coverImage" TEXT,
    "galleryImages" JSONB,
    price NUMERIC,
    "discountPrice" NUMERIC,
    stock INT,
    tags JSONB,
    "featuresIncluded" JSONB,
    requirements JSONB,
    status TEXT,
    "publishDate" TEXT,
    "isFree" BOOLEAN,
    "isPaid" BOOLEAN,
    "fileSize" TEXT,
    format TEXT,
    "downloadUrl" TEXT,
    "driveUrl" TEXT,
    "licenseKey" TEXT,
    "demoUrl" TEXT,
    "authorId" TEXT,
    "authorName" TEXT,
    rating NUMERIC,
    "salesCount" INT,
    "viewsCount" INT,
    "deliveryTimeDays" INT,
    "revisionsAllowed" INT
);

CREATE TABLE orders (
    id TEXT PRIMARY KEY,
    "customerId" TEXT,
    "customerName" TEXT,
    "customerEmail" TEXT,
    "orderDate" TEXT,
    "totalAmount" NUMERIC,
    status TEXT,
    "paymentStatus" TEXT,
    "paymentMethod" TEXT,
    items JSONB,
    "shippingAddress" JSONB
);

-- RLS Policies
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
CREATE POLICY "Users can insert campaigns" ON campaigns FOR INSERT WITH CHECK (true);
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
CREATE POLICY "Users can insert products" ON products FOR INSERT WITH CHECK (true);
-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;

-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
CREATE POLICY "Users can insert applications" ON campaign_applications FOR INSERT WITH CHECK (true);

-- NEUTRALIZED FOR SECURITY: Restricted USING (true) bypass
SELECT 1;
CREATE POLICY "Users can insert orders" ON orders FOR INSERT WITH CHECK (true);
