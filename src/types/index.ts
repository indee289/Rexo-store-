export type UserRole = 'creator' | 'brand' | 'admin';

export type AdminSubRole = 'super_admin' | 'moderator' | 'finance_admin';

export type UserAccountStatus = 'active' | 'suspended' | 'banned' | 'pending_kyc';

export type NicheCategory =
  | 'Tech & Gadgets'
  | 'Fashion & Beauty'
  | 'Gaming & Esports'
  | 'Fitness & Wellness'
  | 'Lifestyle & Travel'
  | 'Business & Finance'
  | 'Entertainment & Comedy'
  | 'Food & Cooking';

export type SocialPlatform = 'instagram' | 'youtube' | 'tiktok' | 'x' | 'linkedin' | 'facebook' | 'other';

export type DeliverableType =
  | 'instagram_reel'
  | 'instagram_story'
  | 'youtube_video'
  | 'tiktok_video'
  | 'x_post'
  | 'dedicated_review';

export interface PortfolioItem {
  id: string;
  title: string;
  brandName: string;
  deliverableType: DeliverableType;
  linkUrl: string;
  thumbnailUrl: string;
  viewsCount: number;
  likesCount: number;
}

export interface UserProfile {
  id: string;
  name: string;
  username: string;
  email: string;
  phone: string;
  avatar: string;
  role: UserRole;
  adminSubRole?: AdminSubRole;
  accountStatus?: UserAccountStatus;
  risk_score?: number;
  trust_score?: number;
  warning_count?: number;
  last_risk_update?: string;
  is_shadow_banned?: boolean;
  suspension_end_date?: string;
  device_hash?: string;
  last_ip_hash?: string;
  isVerified: boolean;
  createdAt: string;
  bio: string;
  location: string;
  niche: NicheCategory;
  age?: number;
  website?: string;
  // Creator specific
  followersCount?: number;
  engagementRate?: number;
  rating?: number;
  kycVerified?: boolean;
  socialLinks?: {
    instagram?: string;
    youtube?: string;
    tiktok?: string;
    x?: string;
    linkedin?: string;
  };
  portfolio?: PortfolioItem[];
  // Brand specific
  brandProfile?: {
    companyName: string;
    industry: string;
    website: string;
    logo: string;
  };
}

export interface Campaign {
  ai_flag_status?: 'safe' | 'flagged' | 'pending_review';
  moderation_reason?: string;
  id: string;
  brandId: string;
  brandName: string;
  brandLogo: string;
  title: string;
  description: string;
  niche: NicheCategory;
  platform: SocialPlatform;
  deliverableType: DeliverableType;
  payoutPerCreator: number;
  totalBudget: number;
  totalSlots: number;
  filledSlots: number;
  minFollowers: number;
  minEngagementRate: number;
  deadline: string;
  requirements: string[];
  status: 'active' | 'completed' | 'paused' | 'draft' | 'rejected';
  createdAt: string;
  escrowStatus?: 'held' | 'released' | 'refunded' | 'partially_released';
  escrowAmount?: number;
  coverImage?: string;
  sampleDemoUrl?: string;
  guidelines?: string;
  dosAndDonts?: string[];
}

export type ApplicationStatus =
  | 'applied'
  | 'shortlisted'
  | 'hired'
  | 'rejected'
  | 'submitted'
  | 'approved'
  | 'paid';

export interface CampaignApplication {
  id: string;
  campaignId: string;
  campaignTitle: string;
  brandName: string;
  creatorId: string;
  creatorName: string;
  creatorAvatar: string;
  creatorHandle: string;
  followersCount: number;
  engagementRate: number;
  proposedPitch: string;
  feeRequested: number;
  deliverableUrl?: string;
  status: ApplicationStatus;
  appliedAt: string;
  submittedAt?: string;
  reviewedAt?: string;
  rejectionReason?: string;
  payoutRemarks?: string;
  paidAt?: string;
}

export interface Wallet {
  userId: string;
  availableBalance: number;
  pendingBalance: number;
  totalEarned: number;
  totalSpent: number;
  escrowHold: number;
  isFrozen?: boolean;
}

export type TransactionType =
  | 'campaign_payout'
  | 'deposit'
  | 'withdrawal'
  | 'escrow_hold'
  | 'escrow_release'
  | 'platform_fee'
  | 'admin_credit'
  | 'admin_debit'
  | 'refund'
  | 'bonus';

export interface WalletTransaction {
  id: string;
  userId: string;
  type: TransactionType;
  amount: number;
  direction: 'credit' | 'debit';
  status: 'completed' | 'pending' | 'failed' | 'rejected';
  note: string;
  referenceId?: string;
  campaignId?: string;
  campaignTitle?: string;
  counterpartyName?: string;
  proofScreenshotUrl?: string;
  adminRemarks?: string;
  createdAt: string;
}

export interface WithdrawalRequest {
  id: string;
  userId: string;
  userName: string;
  userRole: UserRole;
  amount: number;
  method: 'UPI' | 'Bank' | 'PayPal' | 'Manual';
  payoutDetails: {
    upiId?: string;
    accountNumber?: string;
    ifscCode?: string;
    bankName?: string;
    accountHolderName?: string;
    paypalEmail?: string;
  };
  status: 'pending' | 'approved' | 'rejected' | 'held' | 'processing' | 'completed';
  adminNotes?: string;
  createdAt: string;
  resolvedAt?: string;
}

export interface DepositRequest {
  id: string;
  brandId: string;
  brandName: string;
  amount: number;
  paymentMethod: string;
  transactionRef: string;
  proofScreenshotUrl?: string;
  notes?: string;
  status: 'pending' | 'approved' | 'rejected';
  createdAt: string;
  processedAt?: string;
}

export interface DisputeReport {
  id: string;
  reporterId: string;
  reporterName: string;
  targetId: string;
  targetType: 'creator' | 'brand' | 'campaign';
  targetTitle: string;
  reasonType: 'fake_creator' | 'fake_brand' | 'payment_issue' | 'abuse' | 'spam' | 'fraud';
  description: string;
  status: 'open' | 'investigating' | 'resolved' | 'dismissed';
  adminNotes?: string;
  createdAt: string;
  resolvedAt?: string;
}

export interface ShippingAddress {
  id: string;
  userId: string;
  name?: string;
  fullName: string;
  phone: string;
  street: string;
  landmark?: string;
  addressLine1?: string;
  addressLine2?: string;
  city: string;
  state: string;
  pincode: string;
  isDefault: boolean;
  type?: 'home' | 'work' | 'other';
}

export interface Order {
  id: string;
  brandId: string;
  creatorId: string;
  campaignId: string;
  campaignTitle: string;
  amount: number;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  createdAt: string;
  deliverableUrl?: string;
}

export interface AuditLog {
  id: string;
  adminId: string;
  adminName: string;
  adminRole: AdminSubRole;
  action: string;
  targetType: 'user' | 'campaign' | 'wallet' | 'withdrawal' | 'deposit' | 'report' | 'settings' | 'system';
  targetId: string;
  targetName?: string;
  reason?: string;
  ipAddress: string;
  device: string;
  timestamp: string;
}

export interface UserDevice {
  id: string;
  userId: string;
  fcmToken: string;
  platform: 'android' | 'ios' | 'web';
  appVersion: string;
  deviceName: string;
  createdAt: string;
  updatedAt: string;
}

export type NotificationType =
  | 'campaign_approved'
  | 'campaign_rejected'
  | 'campaign_application_accepted'
  | 'campaign_application_rejected'
  | 'creator_selected'
  | 'creator_removed'
  | 'withdrawal_approved'
  | 'withdrawal_rejected'
  | 'deposit_approved'
  | 'deposit_rejected'
  | 'wallet_credited'
  | 'wallet_debited'
  | 'kyc_approved'
  | 'kyc_rejected'
  | 'user_verified'
  | 'admin_broadcast'
  | 'security_alert';

export interface AppNotification {
  id: string;
  userId: string;
  title: string;
  body: string;
  message?: string;
  type: NotificationType;
  payload: {
    screen?: 'CampaignDetails' | 'Wallet' | 'WithdrawalDetails' | 'AdminMessage' | 'KYCStatus' | 'Profile';
    targetId?: string;
    [key: string]: any;
  };
  isRead: boolean;
  deliveryStatus?: 'sent' | 'delivered' | 'failed';
  referenceId?: string;
  createdAt: string;
}

export interface KYCDocument {
  id: string;
  userId: string;
  userName: string;
  documentType: 'pan' | 'aadhaar' | 'gst' | 'passport';
  documentNumber: string;
  documentUrl?: string;
  status: 'pending' | 'verified' | 'rejected';
  submittedAt: string;
  verifiedAt?: string;
  rejectionReason?: string;
}

export interface UserSettings {
  userId: string;
  username: string;
  twoFactorAuth: boolean;
  biometricAuth: boolean;
  pushNotifications: boolean;
  emailNotifications: boolean;
  payoutUpi?: string;
  payoutBank?: string;
  profileVisibility: 'public' | 'private';
  currency: string;
  language: string;
}

export interface SystemSettings {
  platformCommissionRate: number; // e.g. 0.10 = 10%
  escrowFeePercent: number; // e.g. 2%
  minimumWithdrawalAmount: number; // in INR ₹
  maximumWithdrawalAmount: number; // in INR ₹
  kycRequiredForPayout: boolean;
  autoApproveVerifiedCreators: boolean;
  maintenanceMode: boolean;
  featureFlags: {
    enableCryptoPayouts: boolean;
    enableInstantPayouts: boolean;
    enableAiMatching: boolean;
  };
}

// STORE & SUBSCRIPTION TYPES
export type StoreProductType =
  | 'free_resource'
  | 'digital_product'
  | 'physical_product'
  | 'service_package'
  | 'subscription_plan';

export type DigitalProductCategory =
  | 'AI Video Bundle'
  | 'Viral Reel Bundle'
  | 'Instagram Growth Pack'
  | 'Canva Templates'
  | 'Influencer Database'
  | 'UGC Bundle'
  | 'Prompt Bundle'
  | 'Course'
  | 'Ebook'
  | 'Preset Pack'
  | 'Editing Pack';

export type PhysicalProductCategory =
  | 'T-Shirt'
  | 'Hoodie'
  | 'Cap'
  | 'Merchandise'
  | 'Gadgets'
  | 'Mobile Accessories'
  | 'Camera Accessories'
  | 'Studio Equipment';

export type ServiceCategory =
  | 'Instagram Management'
  | 'YouTube Management'
  | 'Social Media Management'
  | 'Video Editing'
  | 'Influencer Marketing'
  | 'UGC Management'
  | 'Brand Promotion'
  | 'Growth Consulting';

export type SubscriptionCategory =
  | 'Creator Pro'
  | 'Brand Pro'
  | 'Agency Pro'
  | 'Marketplace Premium';

export type StoreProductCategory =
  | DigitalProductCategory
  | PhysicalProductCategory
  | ServiceCategory
  | SubscriptionCategory
  | string;

export interface StoreProduct {
  id: string;
  title: string;
  productType: StoreProductType;
  category: StoreProductCategory;
  shortDescription: string;
  fullDescription: string;
  coverImage: string;
  galleryImages: string[];
  price: number; // 0 if free
  discountPrice?: number;
  stock: number;
  tags: string[];
  featuresIncluded: string[];
  requirements?: string[];
  status: 'active' | 'paused' | 'draft';
  publishDate: string;

  // Toggles
  isFree: boolean;
  isPaid: boolean;
  isFeatured: boolean;
  isRecommended: boolean;
  isVisible: boolean;

  // Digital Product Logic
  downloadUrl?: string;
  driveUrl?: string;
  fileType?: 'ZIP' | 'PDF' | 'Video' | 'Link' | 'Drive';
  licenseKey?: string;

  // Physical Product Logic
  weight?: string;
  colors?: string[];
  sizes?: string[];
  sku?: string;
  shippingFee?: number;
  estimatedDelivery?: string;

  // Stats
  rating: number;
  salesCount: number;
  viewsCount: number;
}

export interface StoreOrderItem {
  productId: string;
  productTitle: string;
  productType: StoreProductType;
  coverImage: string;
  price: number;
  quantity: number;
  selectedColor?: string;
  selectedSize?: string;
  downloadUrl?: string;
  driveUrl?: string;
  licenseKey?: string;
}

export interface StoreOrder {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  items: StoreOrderItem[];
  totalAmount: number;
  productType: StoreProductType;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'unlocked';
  shippingAddress?: ShippingAddress;
  paymentMethod: string;
  transactionRef: string;
  createdAt: string;
  unlockedAt?: string;
}

export interface CartItem {
  productId: string;
  product: StoreProduct;
  quantity: number;
  selectedColor?: string;
  selectedSize?: string;
}

export interface SubscriptionPlan {
  id: string;
  name: SubscriptionCategory;
  price: number;
  duration: 'monthly' | 'yearly';
  features: string[];
  status: 'active' | 'paused';
}

export interface UserSubscription {
  id: string;
  userId: string;
  planId: string;
  planName: string;
  startDate: string;
  expiryDate: string;
  status: 'active' | 'expired' | 'cancelled';
}


export interface ChatMessage {
  is_hidden_by_ai?: boolean;
  id: string;
  campaignId: string;
  senderId: string; // userId
  receiverId: string; // userId
  text: string;
  timestamp: string;
  read: boolean;
}

export interface ChatThread {
  id: string; // could be campaignId
  campaignId: string;
  brandId: string;
  creatorId: string;
  lastMessage?: ChatMessage;
  unreadCount: number;
}
