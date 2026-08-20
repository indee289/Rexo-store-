import {
  UserProfile,
  AdminSubRole,
  UserAccountStatus,
  Campaign,
  CampaignApplication,
  Wallet,
  WalletTransaction,
  WithdrawalRequest,
  DepositRequest,
  DisputeReport,
  AuditLog,
  AppNotification,
  UserDevice,
  KYCDocument,
  UserSettings,
  SystemSettings,
  StoreProduct,
  StoreOrder,
  CartItem,
  SubscriptionPlan,
  UserSubscription,
} from '../types';

export interface AppState {
  currentUser: UserProfile | null;
  users: UserProfile[];
  campaigns: Campaign[];
  applications: CampaignApplication[];
  wallets: Record<string, Wallet>;
  transactions: WalletTransaction[];
  withdrawals: WithdrawalRequest[];
  deposits: DepositRequest[];
  disputes: DisputeReport[];
  auditLogs: AuditLog[];
  notifications: AppNotification[];
  userDevices: UserDevice[];
  kycDocuments: KYCDocument[];
  userSettings: Record<string, UserSettings>;
  systemSettings: SystemSettings;
  products: StoreProduct[];
  orders: StoreOrder[];
  cart: CartItem[];
  wishlist: string[];
  subscriptionPlans: SubscriptionPlan[];
  userSubscriptions: UserSubscription[];
}

export function getInitialState(): AppState {
  return {
    currentUser: null,
    users: [],
    campaigns: [],
    applications: [],
    wallets: {},
    transactions: [],
    withdrawals: [],
    deposits: [],
    disputes: [],
    auditLogs: [],
    notifications: [],
    userDevices: [],
    kycDocuments: [],
    userSettings: {},
    systemSettings: {
      platformCommissionRate: 0.10,
      escrowFeePercent: 0.02,
      minimumWithdrawalAmount: 1000,
      maximumWithdrawalAmount: 100000,
      kycRequiredForPayout: true,
      autoApproveVerifiedCreators: false,
      maintenanceMode: false,
      featureFlags: { enableCryptoPayouts: false, enableInstantPayouts: false, enableAiMatching: false }
    },
    products: [],
    orders: [],
    cart: [],
    wishlist: [],
    subscriptionPlans: [],
    userSubscriptions: [],
  };
}

// Disable local storage engine - we are using Supabase now
export function saveState(state: AppState): void {
  // No-op
}

export function loadState(): AppState {
  return getInitialState();
}
