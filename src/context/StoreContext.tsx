import { supabaseDataService } from '../services/supabaseDataService';
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import {
  UserProfile,
  UserRole,
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
  NotificationType,
  UserDevice,
  KYCDocument,
  UserSettings,
  SystemSettings,
  StoreProduct,
  StoreOrder,
  StoreOrderItem,
  CartItem,
  SubscriptionPlan,
  UserSubscription,
  ShippingAddress,
} from '../types';
import { AppState, loadState, saveState, getInitialState } from '../services/storeEngine';
import { NativePermissionModal, PermissionRequest } from '../components/common/NativePermissionModal';
import { fcmService } from '../services/fcmService';
import { deepLinkService } from '../services/deepLinkService';
import { Bell, Sparkles, X, ChevronRight } from 'lucide-react';

interface StoreContextType {
  state: AppState;
  currentUser: UserProfile | null;
  currentWallet: Wallet;
  userSettings: UserSettings;
  systemSettings: SystemSettings;
  unreadNotificationsCount: number;
  requestNativePermission: (type: 'notifications' | 'gallery' | 'camera') => Promise<boolean>;

  // Notification Management
  markNotificationAsRead: (id: string) => void;
  markAllNotificationsAsRead: () => void;
  deleteNotification: (id: string) => void;
  refreshNotifications: () => Promise<void>;
  triggerPushNotification: (params: {
    userId: string;
    title: string;
    body: string;
    type: NotificationType;
    payload?: any;
  }) => Promise<void>;

  // Standard User Actions
  updateUserProfile: (updates: Partial<UserProfile>) => void;
  updateUserSettings: (updates: Partial<UserSettings>) => void;
  switchRole: (role: 'creator' | 'brand') => void;
  setRealSessionUser: (profile: UserProfile | null) => void;
  resetApp: () => void;
  createCampaign: (data: Omit<Campaign, 'id' | 'brandId' | 'brandName' | 'brandLogo' | 'filledSlots' | 'status' | 'createdAt'>) => void;
  applyToCampaign: (campaignId: string, proposedPitch: string, feeRequested: number) => void;
  updateApplicationStatus: (appId: string, status: CampaignApplication['status'], deliverableUrl?: string) => void;
  submitDeliverable: (appId: string, deliverableUrl: string) => { success: boolean; message: string };
  adminApproveContentSubmission: (appId: string, adminNotes?: string) => { success: boolean; message: string };
  adminRejectContentSubmission: (appId: string, reason: string) => { success: boolean; message: string };
  adminDisburseCampaignPayout: (appId: string, remarks: string, amountOverride?: number) => { success: boolean; message: string };
  requestWithdrawal: (
    amount: number,
    method: 'UPI' | 'Bank' | 'PayPal' | 'Manual',
    details: WithdrawalRequest['payoutDetails']
  ) => { success: boolean; message: string };
  requestDeposit: (
    amount: number,
    paymentMethod: string,
    transactionRef: string,
    proofScreenshotUrl?: string,
    notes?: string
  ) => { success: boolean; message: string };
  depositBrandFunds: (
    amount: number,
    paymentMethod: string,
    transactionRef: string,
    proofScreenshotUrl?: string,
    notes?: string
  ) => { success: boolean; message: string };
  createReport: (report: Omit<DisputeReport, 'id' | 'reporterId' | 'reporterName' | 'createdAt' | 'status'>) => void;

  // Admin Actions (Controlled & Audit Logged)
  adminUpdateUserRole: (userId: string, newRole: UserRole, adminSubRole?: AdminSubRole, reason?: string) => void;
  adminSetUserStatus: (userId: string, status: UserAccountStatus, reason?: string) => void;
  adminVerifyUser: (userId: string, isVerified: boolean, reason?: string) => void;
  adminDeleteUser: (userId: string, reason?: string) => void;
  adminResetUserKyc: (userId: string, reason?: string) => void;
  adminResetUserPassword: (userId: string, reason?: string) => void;
  adminAdjustUserWallet: (userId: string, amount: number, direction: 'credit' | 'debit', note: string, reason?: string) => void;
  adminSetWalletFreeze: (userId: string, isFrozen: boolean, reason?: string) => void;
  adminSetCampaignStatus: (campaignId: string, status: Campaign['status'], reason?: string) => void;
  adminDeleteCampaign: (campaignId: string, reason?: string) => void;
  adminForceCompleteCampaign: (campaignId: string, reason?: string) => void;
  adminForceCancelCampaign: (campaignId: string, reason?: string) => void;
  adminReleaseEscrow: (campaignId: string, type: 'full' | 'partial' | 'refund', amount?: number, reason?: string) => void;
  adminProcessWithdrawal: (withdrawalId: string, action: WithdrawalRequest['status'], notes?: string, reason?: string) => void;
  adminProcessDeposit: (depositId: string, action: DepositRequest['status'], reason?: string) => void;
  adminProcessDispute: (disputeId: string, action: DisputeReport['status'], notes?: string) => void;
  adminProcessKycDoc: (docId: string, action: 'verified' | 'rejected', rejectionReason?: string) => void;
  adminUpdateSystemSettings: (newSettings: Partial<SystemSettings>, reason?: string) => void;
  adminSendBroadcast: (title: string, message: string, targetAudience: string) => void;

  // STORE & SUBSCRIPTION MODULE
  createProduct: (data: Omit<StoreProduct, 'id' | 'rating' | 'salesCount' | 'viewsCount' | 'publishDate'>) => void;
  updateProduct: (productId: string, updates: Partial<StoreProduct>) => void;
  deleteProduct: (productId: string) => void;
  addToCart: (product: StoreProduct, quantity?: number, selectedColor?: string, selectedSize?: string) => void;
  removeFromCart: (productId: string) => void;
  clearCart: () => void;
  checkoutOrder: (params: {
    items: { product: StoreProduct; quantity: number; selectedColor?: string; selectedSize?: string }[];
    shippingAddress?: ShippingAddress;
    paymentMethod: string;
  }) => { success: boolean; orderId: string; message: string };
  subscribeToPlan: (planId: string) => { success: boolean; message: string };
  toggleWishlist: (productId: string) => void;
  adminUpdateOrderStatus: (orderId: string, status: StoreOrder['status']) => void;
}

const StoreContext = createContext<StoreContextType | undefined>(undefined);

export const StoreProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [permissionRequest, setPermissionRequest] = useState<PermissionRequest | null>(null);
  const [state, setState] = useState<AppState>(() => loadState());

  useEffect(() => {
    saveState(state);
  }, [state]);

  // LOAD SUPABASE DATA ON MOUNT
  useEffect(() => {
    const loadData = async () => {
      try {
        const [campaigns, products] = await Promise.all([
          supabaseDataService.fetchCampaigns(),
          supabaseDataService.fetchProducts()
        ]);
        
        setState((prev) => ({
          ...prev,
          campaigns: campaigns.length > 0 ? campaigns : prev.campaigns,
          products: products.length > 0 ? products : prev.products
        }));
      } catch (err) {
        console.warn('Failed to load initial data from Supabase:', err);
      }
    };
    loadData();
  }, []);

  const currentUser = state.currentUser;

  const currentWallet: Wallet = (currentUser ? state.wallets[currentUser.id] : undefined) || {
    userId: currentUser?.id || "",
    availableBalance: 0,
    pendingBalance: 0,
    totalEarned: 0,
    totalSpent: 0,
    escrowHold: 0,
    isFrozen: false,
  };

  const userSettings: UserSettings = (currentUser ? state.userSettings[currentUser.id] : undefined) || {
    userId: currentUser?.id || "",
    username: currentUser?.username || "",
    twoFactorAuth: false,
    biometricAuth: false,
    pushNotifications: true,
    emailNotifications: true,
    profileVisibility: 'public',
    currency: 'INR',
    language: 'English',
  };

  const unreadNotificationsCount = state.notifications.filter((n) => n.userId === currentUser?.id && !n.isRead).length;

  const [activePushToast, setActivePushToast] = useState<AppNotification | null>(null);

  // Initialize FCM for user on boot
  useEffect(() => {
    if (currentUser?.id) {
      const initPush = async () => {
        // If not already granted/denied, ask via our custom modal first
        if ('Notification' in window && Notification.permission === 'default') {
          const allowed = await requestNativePermission('notifications');
          if (allowed) {
            fcmService.initializeFCM(currentUser.id);
          }
        } else {
          fcmService.initializeFCM(currentUser.id);
        }
      };
      initPush();
    }

    const unsubscribe = fcmService.onForegroundMessage((notif) => {
      setActivePushToast(notif);
      setTimeout(() => {
        setActivePushToast((current) => (current?.id === notif.id ? null : current));
      }, 5500);
    });

    return () => {
      unsubscribe();
    };
  }, [currentUser?.id]);

  // Push Notification Handler Function
  
  const requestNativePermission = (type: 'notifications' | 'gallery' | 'camera'): Promise<boolean> => {
    return new Promise((resolve) => {
      let title = '';
      let description = '';

      if (type === 'notifications') {
        if ('Notification' in window && Notification.permission !== 'default') {
           resolve(Notification.permission === 'granted');
           return;
        }
        title = 'Allow this app to send you notifications?';
        description = 'You will receive updates about campaigns, wallet transactions, and messages.';
      } else if (type === 'gallery') {
        title = 'Allow this device to access photos and videos?';
        description = 'This device will be able to access photos and videos while it is connected to your profile.';
      } else {
        title = `Allow access to ${type}?`;
        description = `We need access to your ${type} to continue.`;
      }

      setPermissionRequest({
        title,
        description,
        onAllow: () => {
          setPermissionRequest(null);
          resolve(true);
        },
        onDeny: () => {
          setPermissionRequest(null);
          resolve(false);
        }
      });
    });
  };

  const triggerPushNotification = async (params: {
    userId: string;
    title: string;
    body: string;
    type: NotificationType;
    payload?: any;
  }) => {
    const newNotif: AppNotification = {
      id: `notif_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId: params.userId,
      title: params.title,
      body: params.body,
      type: params.type,
      payload: params.payload || {},
      isRead: false,
      deliveryStatus: 'delivered',
      createdAt: new Date().toISOString(),
    };

    setState((prev) => ({
      ...prev,
      notifications: [newNotif, ...prev.notifications],
    }));

    // Dispatch foreground overlay
    fcmService.dispatchIncomingNotification(newNotif);

    // Call server API
    try {
      await fetch('/api/notifications/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });
    } catch (err) {
      console.warn('[Push Notification] Server endpoint fetch fallback:', err);
    }
  };

  const markNotificationAsRead = (id: string) => {
    setState((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) => (n.id === id ? { ...n, isRead: true } : n)),
    }));
    fetch(`/api/notifications/${id}/read`, { method: 'PATCH' }).catch(() => {});
  };

  const markAllNotificationsAsRead = () => {
    setState((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) => ({ ...n, isRead: true })),
    }));
    fetch(`/api/notifications/user/${currentUser.id}/read-all`, { method: 'PATCH' }).catch(() => {});
  };

  const deleteNotification = (id: string) => {
    setState((prev) => ({
      ...prev,
      notifications: prev.notifications.filter((n) => n.id !== id),
    }));
    fetch(`/api/notifications/${id}`, { method: 'DELETE' }).catch(() => {});
  };

  const refreshNotifications = async () => {
    try {
      const res = await fetch(`/api/notifications/${currentUser.id}`);
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data.notifications)) {
          setState((prev) => ({
            ...prev,
            notifications: data.notifications,
          }));
        }
      }
    } catch (err) {
      console.warn('[Refresh Notifications] Local store active.');
    }
  };

  // Audit Log Helper Function
  const logAuditAction = (
    action: string,
    targetType: AuditLog['targetType'],
    targetId: string,
    targetName?: string,
    reason?: string
  ) => {
    const newLog: AuditLog = {
      id: `audit_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      adminId: currentUser.id,
      adminName: currentUser.name,
      adminRole: currentUser.adminSubRole || 'super_admin',
      action,
      targetType,
      targetId,
      targetName,
      reason: reason || 'Admin manual override',
      ipAddress: '103.21.124.8',
      device: 'Admin Console macOS/Mobile',
      timestamp: new Date().toISOString(),
    };

    return newLog;
  };

  // Standard User Handlers
  const updateUserProfile = async (updates: Partial<UserProfile>) => {
    setState((prev) => {
      const updatedUser = { ...prev.currentUser, ...updates };
      const updatedUsers = prev.users.map((u) => (u.id === updatedUser.id ? updatedUser : u));
      return {
        ...prev,
        currentUser: updatedUser,
        users: updatedUsers,
      };
    });
    
    try {
      await supabaseDataService.updateUserProfile(currentUser.id, updates);
    } catch (err) {
      console.error('Failed to sync profile update to Supabase', err);
    }
  };

  const updateUserSettings = (updates: Partial<UserSettings>) => {
    setState((prev) => ({
      ...prev,
      userSettings: {
        ...prev.userSettings,
        [currentUser.id]: {
          ...(prev.userSettings[currentUser.id] || {}),
          ...updates,
        },
      },
    }));
  };

  const switchRole = (newRole: 'creator' | 'brand') => {
    // Only allows switching between creator & brand
    setState((prev) => {
      const updatedUser = { ...prev.currentUser, role: newRole as UserRole };
      const updatedUsers = prev.users.map((u) => (u.id === updatedUser.id ? updatedUser : u));
      return {
        ...prev,
        currentUser: updatedUser,
        users: updatedUsers,
      };
    });
  };
  const setRealSessionUser = (profile: UserProfile | null) => {
    setState((prev) => ({ ...prev, currentUser: profile }));
  };


  const resetApp = () => {
    const initialState = getInitialState();
    setState(initialState);
    saveState(initialState);
  };

  const createCampaign = async (data: Omit<Campaign, 'id' | 'brandId' | 'brandName' | 'brandLogo' | 'filledSlots' | 'status' | 'createdAt'>) => {
    const newCampaign: Campaign = {
      ...data,
      id: `camp_${Date.now()}`,
      brandId: currentUser.id,
      brandName: currentUser.name,
      brandLogo: currentUser.avatar,
      filledSlots: 0,
      status: 'active',
      createdAt: new Date().toISOString(),
      escrowStatus: 'held',
      escrowAmount: data.totalBudget,
    };

    setState((prev) => ({
      ...prev,
      campaigns: [newCampaign, ...prev.campaigns],
    }));
    
    // Persist to DB
    try {
      await supabaseDataService.createCampaign(newCampaign);
    } catch (err) {
      console.warn('Failed to save campaign to DB', err);
    }
  };

  const applyToCampaign = (campaignId: string, proposedPitch: string, feeRequested: number) => {
    const campaign = state.campaigns.find((c) => c.id === campaignId);
    if (!campaign) return;

    const newApp: CampaignApplication = {
      id: `app_${Date.now()}`,
      campaignId,
      campaignTitle: campaign.title,
      brandName: campaign.brandName,
      creatorId: currentUser.id,
      creatorName: currentUser.name,
      creatorAvatar: currentUser.avatar,
      creatorHandle: `@${currentUser.username}`,
      followersCount: currentUser.followersCount || 0,
      engagementRate: currentUser.engagementRate || 0,
      proposedPitch,
      feeRequested,
      status: 'applied',
      appliedAt: new Date().toISOString(),
    };

    setState((prev) => ({
      ...prev,
      applications: [newApp, ...prev.applications],
    }));
  };

  const updateApplicationStatus = (appId: string, status: CampaignApplication['status'], deliverableUrl?: string) => {
    setState((prev) => {
      const updatedApps = prev.applications.map((app) => {
        if (app.id !== appId) return app;
        return {
          ...app,
          status,
          deliverableUrl: deliverableUrl || app.deliverableUrl,
          reviewedAt: new Date().toISOString(),
        };
      });
      return { ...prev, applications: updatedApps };
    });
  };

  const submitDeliverable = (appId: string, deliverableUrl: string) => {
    const targetApp = state.applications.find((a) => a.id === appId);
    if (!targetApp) {
      return { success: false, message: 'Application record not found.' };
    }

    if (!deliverableUrl || !deliverableUrl.trim().startsWith('http')) {
      return { success: false, message: 'Please enter a valid URL (e.g., https://instagram.com/p/...)' };
    }

    const cleanUrl = deliverableUrl.trim();

    setState((prev) => ({
      ...prev,
      applications: prev.applications.map((a) => {
        if (a.id !== appId) return a;
        return {
          ...a,
          deliverableUrl: cleanUrl,
          status: 'submitted' as const,
          submittedAt: new Date().toISOString(),
        };
      }),
    }));

    triggerPushNotification({
      userId: 'usr_admin_master',
      title: 'New Content Submission 🎬',
      body: `@${currentUser.username} submitted campaign deliverable link for ${targetApp.campaignTitle}.`,
      type: 'campaign_approved',
      payload: { screen: 'CampaignDetails', targetId: targetApp.campaignId },
    });

    return {
      success: true,
      message: 'Promotional content link submitted successfully! Admin/Brand will verify your Reel/Story.',
    };
  };

  const adminApproveContentSubmission = (appId: string, adminNotes?: string) => {
    const targetApp = state.applications.find((a) => a.id === appId);
    if (!targetApp) return { success: false, message: 'Application not found.' };

    setState((prev) => ({
      ...prev,
      applications: prev.applications.map((a) => {
        if (a.id !== appId) return a;
        return {
          ...a,
          status: 'approved' as const,
          reviewedAt: new Date().toISOString(),
        };
      }),
    }));

    triggerPushNotification({
      userId: targetApp.creatorId,
      title: 'Content Approved! 🎉',
      body: `Your promotional content for '${targetApp.campaignTitle}' was approved by Admin! Ready for payout clearance.`,
      type: 'campaign_approved',
      payload: { screen: 'CampaignDetails', targetId: targetApp.campaignId },
    });

    return { success: true, message: `Content deliverable for ${targetApp.creatorName} approved!` };
  };

  const adminRejectContentSubmission = (appId: string, reason: string) => {
    const targetApp = state.applications.find((a) => a.id === appId);
    if (!targetApp) return { success: false, message: 'Application not found.' };

    setState((prev) => ({
      ...prev,
      applications: prev.applications.map((a) => {
        if (a.id !== appId) return a;
        return {
          ...a,
          status: 'rejected' as const,
          rejectionReason: reason,
          reviewedAt: new Date().toISOString(),
        };
      }),
    }));

    triggerPushNotification({
      userId: targetApp.creatorId,
      title: 'Content Revision / Rejected ⚠️',
      body: `Your content for '${targetApp.campaignTitle}' was rejected. Reason: ${reason || 'Does not match campaign guidelines'}`,
      type: 'campaign_rejected',
      payload: { screen: 'CampaignDetails', targetId: targetApp.campaignId },
    });

    return { success: true, message: `Content deliverable rejected with reason: "${reason}"` };
  };

  const adminDisburseCampaignPayout = (appId: string, remarks: string, amountOverride?: number) => {
    const targetApp = state.applications.find((a) => a.id === appId);
    if (!targetApp) return { success: false, message: 'Application record not found.' };

    const campaign = state.campaigns.find((c) => c.id === targetApp.campaignId);
    const payoutAmount = amountOverride || targetApp.feeRequested || (campaign ? campaign.payoutPerCreator : 3500);

    const audit = logAuditAction(
      `Disburse Campaign Payout ₹${payoutAmount}`,
      'campaign',
      targetApp.campaignId,
      targetApp.creatorName,
      remarks
    );

    const payoutTx: WalletTransaction = {
      id: `tx_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId: targetApp.creatorId,
      type: 'campaign_payout',
      amount: payoutAmount,
      direction: 'credit',
      status: 'completed',
      note: `Campaign Payout: ${targetApp.campaignTitle} - Remarks: ${remarks || 'Paid Out by Admin'}`,
      referenceId: targetApp.id,
      campaignId: targetApp.campaignId,
      campaignTitle: targetApp.campaignTitle,
      counterpartyName: targetApp.brandName || 'Brand Sponsor Escrow',
      createdAt: new Date().toISOString(),
    };

    setState((prev) => {
      const creatorWallet = prev.wallets[targetApp.creatorId] || {
        userId: targetApp.creatorId,
        availableBalance: 0,
        pendingBalance: 0,
        totalEarned: 0,
        totalSpent: 0,
        escrowHold: 0,
        isFrozen: false,
      };

      const updatedWallet: Wallet = {
        ...creatorWallet,
        availableBalance: creatorWallet.availableBalance + payoutAmount,
        totalEarned: creatorWallet.totalEarned + payoutAmount,
      };

      const updatedApps = prev.applications.map((a) => {
        if (a.id !== appId) return a;
        return {
          ...a,
          status: 'paid' as const,
          payoutRemarks: remarks || 'Paid Out',
          paidAt: new Date().toISOString(),
        };
      });

      const updatedCamps = prev.campaigns.map((c) => {
        if (c.id !== targetApp.campaignId) return c;
        return {
          ...c,
          filledSlots: (c.filledSlots || 0) + 1,
        };
      });

      return {
        ...prev,
        wallets: {
          ...prev.wallets,
          [targetApp.creatorId]: updatedWallet,
        },
        applications: updatedApps,
        campaigns: updatedCamps,
        transactions: [payoutTx, ...prev.transactions],
        auditLogs: [audit, ...prev.auditLogs],
      };
    });

    triggerPushNotification({
      userId: targetApp.creatorId,
      title: 'Campaign Payout Released! 💰💸',
      body: `₹${payoutAmount.toLocaleString('en-IN')} has been added to your wallet for '${targetApp.campaignTitle}'. Remarks: ${remarks || 'Paid Out'}`,
      type: 'campaign_approved',
      payload: { screen: 'Wallet', targetId: targetApp.creatorId },
    });

    return {
      success: true,
      message: `Successfully paid out ₹${payoutAmount.toLocaleString('en-IN')} to ${targetApp.creatorName}! Status set to Paid Out.`,
    };
  };

  const requestWithdrawal = (
    amount: number,
    method: 'UPI' | 'Bank' | 'PayPal' | 'Manual',
    details: WithdrawalRequest['payoutDetails']
  ) => {
    const userWallet = (currentUser ? state.wallets[currentUser.id] : undefined) || {
      userId: currentUser?.id || "",
      availableBalance: 175000,
      pendingBalance: 25000,
      totalEarned: 425000,
      totalSpent: 0,
      escrowHold: 25000,
      isFrozen: false,
    };

    if (userWallet.isFrozen) {
      return { success: false, message: 'Your wallet is frozen by compliance administration. Contact support.' };
    }

    if (amount <= 0) {
      return { success: false, message: 'Please enter a valid withdrawal amount.' };
    }

    if (userWallet.availableBalance < amount) {
      return { success: false, message: `Insufficient available balance! Maximum requestable: ₹${userWallet.availableBalance.toLocaleString('en-IN')}` };
    }

    const newReq: WithdrawalRequest = {
      id: `w_${Date.now()}`,
      userId: currentUser?.id || "",
      userName: currentUser.name,
      userRole: currentUser.role,
      amount,
      method,
      payoutDetails: details,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    const newTx: WalletTransaction = {
      id: `tx_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId: currentUser?.id || "",
      type: 'withdrawal',
      amount,
      direction: 'debit',
      status: 'pending',
      note: `Withdrawal request via ${method} (${details.bankName || details.upiId || 'Bank Account'})`,
      referenceId: newReq.id,
      counterpartyName: details.bankName || 'Direct Payout Gateway',
      createdAt: new Date().toISOString(),
    };

    setState((prev) => {
      const prevWallet = prev.wallets[currentUser.id] || {
        userId: currentUser?.id || "",
        availableBalance: 175000,
        pendingBalance: 25000,
        totalEarned: 425000,
        totalSpent: 0,
        escrowHold: 25000,
        isFrozen: false,
      };

      const updatedWallet = {
        ...prevWallet,
        availableBalance: Math.max(0, prevWallet.availableBalance - amount),
        pendingBalance: prevWallet.pendingBalance + amount,
      };

      return {
        ...prev,
        wallets: {
          ...prev.wallets,
          [currentUser.id]: updatedWallet,
        },
        withdrawals: [newReq, ...prev.withdrawals],
        transactions: [newTx, ...prev.transactions],
      };
    });

    triggerPushNotification({
      userId: 'usr_admin_master',
      title: 'New Withdrawal Request 💸',
      body: `${currentUser.name} requested a ₹${amount.toLocaleString('en-IN')} payout via ${method}.`,
      type: 'withdrawal_approved',
      payload: { screen: 'Wallet', targetId: newReq.id },
    });

    return { success: true, message: `Withdrawal request of ₹${amount.toLocaleString('en-IN')} submitted successfully for clearance.` };
  };

  const requestDeposit = (
    amount: number,
    paymentMethod: string,
    transactionRef: string,
    proofScreenshotUrl?: string,
    notes?: string
  ) => {
    if (amount <= 0) {
      return { success: false, message: 'Please enter a valid deposit amount.' };
    }

    if (!transactionRef || transactionRef.trim().length < 4) {
      return { success: false, message: 'Please enter a valid transaction reference / UTR number.' };
    }

    const newDep: DepositRequest = {
      id: `dep_${Date.now()}`,
      brandId: currentUser.id,
      brandName: currentUser.name,
      amount,
      paymentMethod,
      transactionRef,
      proofScreenshotUrl,
      notes,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    const newTx: WalletTransaction = {
      id: `tx_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId: currentUser?.id || "",
      type: 'deposit',
      amount,
      direction: 'credit',
      status: 'pending',
      note: `Deposit via ${paymentMethod} (Ref: ${transactionRef})`,
      referenceId: transactionRef,
      proofScreenshotUrl,
      adminRemarks: notes,
      createdAt: new Date().toISOString(),
    };

    setState((prev) => ({
      ...prev,
      deposits: [newDep, ...prev.deposits],
      transactions: [newTx, ...prev.transactions],
    }));

    triggerPushNotification({
      userId: 'usr_admin_master',
      title: 'New Deposit Request 💰',
      body: `${currentUser.name} submitted a ₹${amount.toLocaleString('en-IN')} deposit request (Ref: ${transactionRef}).`,
      type: 'deposit_approved',
      payload: { screen: 'Wallet', targetId: newDep.id },
    });

    return { success: true, message: `Deposit request of ₹${amount.toLocaleString('en-IN')} submitted. Pending admin clearance.` };
  };

  const depositBrandFunds = requestDeposit;

  const createReport = (report: Omit<DisputeReport, 'id' | 'reporterId' | 'reporterName' | 'createdAt' | 'status'>) => {
    const newDispute: DisputeReport = {
      ...report,
      id: `disp_${Date.now()}`,
      reporterId: currentUser.id,
      reporterName: currentUser.name,
      status: 'open',
      createdAt: new Date().toISOString(),
    };

    setState((prev) => ({
      ...prev,
      disputes: [newDispute, ...prev.disputes],
    }));
  };

  // Admin Actions
  const adminUpdateUserRole = (userId: string, newRole: UserRole, adminSubRole?: AdminSubRole, reason?: string) => {
    supabaseDataService.updateRecord('users', userId, { role: newRole });
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction('Role Assignment', 'user', userId, targetUser?.name, reason);

    setState((prev) => {
      const updatedUsers = prev.users.map((u) => {
        if (u.id !== userId) return u;
        return { ...u, role: newRole, adminSubRole: adminSubRole || u.adminSubRole };
      });

      return {
        ...prev,
        users: updatedUsers,
        auditLogs: [audit, ...prev.auditLogs],
      };
    });
  };

  const adminSetUserStatus = (userId: string, status: UserAccountStatus, reason?: string) => {
    supabaseDataService.updateRecord('users', userId, { status });
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction(`Status: ${status.toUpperCase()}`, 'user', userId, targetUser?.name, reason);

    setState((prev) => ({
      ...prev,
      users: prev.users.map((u) => (u.id === userId ? { ...u, accountStatus: status } : u)),
      auditLogs: [audit, ...prev.auditLogs],
    }));
  };

  const adminVerifyUser = (userId: string, isVerified: boolean, reason?: string) => {
    supabaseDataService.updateRecord('users', userId, { kyc_status: isVerified ? 'verified' : 'unverified' });
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction(isVerified ? 'Assign Verified Badge' : 'Revoke Verified Badge', 'user', userId, targetUser?.name, reason);

    setState((prev) => ({
      ...prev,
      users: prev.users.map((u) => (u.id === userId ? { ...u, isVerified } : u)),
      auditLogs: [audit, ...prev.auditLogs],
    }));

    triggerPushNotification({
      userId,
      title: isVerified ? 'Account Verified! 🌟' : 'Verified Badge Update',
      body: isVerified ? 'Congratulations! Your profile has been assigned a verified badge.' : 'Your account verification status has been updated.',
      type: 'user_verified',
      payload: { screen: 'Profile', targetId: userId },
    });
  };

  const adminDeleteUser = (userId: string, reason?: string) => {
    supabaseDataService.deleteRecord('users', userId);
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction('Delete Account', 'user', userId, targetUser?.name, reason);

    setState((prev) => ({
      ...prev,
      users: prev.users.filter((u) => u.id !== userId),
      auditLogs: [audit, ...prev.auditLogs],
    }));
  };

  const adminResetUserKyc = (userId: string, reason?: string) => {
    supabaseDataService.updateRecord('users', userId, { kyc_status: 'unverified' });
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction('Reset KYC Verification', 'user', userId, targetUser?.name, reason);

    setState((prev) => ({
      ...prev,
      users: prev.users.map((u) => (u.id === userId ? { ...u, kycVerified: false } : u)),
      auditLogs: [audit, ...prev.auditLogs],
    }));

    triggerPushNotification({
      userId,
      title: 'KYC Status Reset ⚠️',
      body: 'Your identity verification documents have been reset. Please submit updated KYC.',
      type: 'kyc_rejected',
      payload: { screen: 'KYCStatus', targetId: userId },
    });
  };

  const adminResetUserPassword = (userId: string, reason?: string) => {
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction('Force Password Reset Token', 'user', userId, targetUser?.name, reason);

    setState((prev) => ({
      ...prev,
      auditLogs: [audit, ...prev.auditLogs],
    }));

    triggerPushNotification({
      userId,
      title: 'Security Alert 🔒',
      body: 'A security password reset token was initiated for your account.',
      type: 'security_alert',
      payload: { screen: 'Profile', targetId: userId },
    });
  };

  const adminAdjustUserWallet = (userId: string, amount: number, direction: 'credit' | 'debit', note: string, reason?: string) => {
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction(`Wallet ${direction.toUpperCase()} ₹${amount}`, 'wallet', userId, targetUser?.name, reason);

    const newTx: WalletTransaction = {
      id: `tx_${Date.now()}`,
      userId,
      type: direction === 'credit' ? 'admin_credit' : 'admin_debit',
      amount,
      direction,
      status: 'completed',
      note: note || `Admin manual ${direction}`,
      createdAt: new Date().toISOString(),
    };

    setState((prev) => {
      const userWallet = prev.wallets[userId] || {
        userId,
        availableBalance: 0,
        pendingBalance: 0,
        totalEarned: 0,
        totalSpent: 0,
        escrowHold: 0,
      };

      const delta = direction === 'credit' ? amount : -amount;
      const updatedWallet: Wallet = {
        ...userWallet,
        availableBalance: Math.max(0, userWallet.availableBalance + delta),
      };

      return {
        ...prev,
        wallets: { ...prev.wallets, [userId]: updatedWallet },
        transactions: [newTx, ...prev.transactions],
        auditLogs: [audit, ...prev.auditLogs],
      };
    });

    triggerPushNotification({
      userId,
      title: direction === 'credit' ? 'Wallet Credited 💳' : 'Wallet Debited 📉',
      body: `₹${amount} was ${direction === 'credit' ? 'credited to' : 'debited from'} your wallet. Note: ${note || 'Admin adjustment'}`,
      type: direction === 'credit' ? 'wallet_credited' : 'wallet_debited',
      payload: { screen: 'Wallet', targetId: userId },
    });
  };

  const adminSetWalletFreeze = (userId: string, isFrozen: boolean, reason?: string) => {
    supabaseDataService.updateRecord('wallets', userId, { is_frozen: isFrozen });
    const targetUser = state.users.find((u) => u.id === userId);
    const audit = logAuditAction(isFrozen ? 'Freeze Wallet' : 'Unfreeze Wallet', 'wallet', userId, targetUser?.name, reason);

    setState((prev) => {
      const userWallet = prev.wallets[userId] || {
        userId,
        availableBalance: 0,
        pendingBalance: 0,
        totalEarned: 0,
        totalSpent: 0,
        escrowHold: 0,
      };

      return {
        ...prev,
        wallets: { ...prev.wallets, [userId]: { ...userWallet, isFrozen } },
        auditLogs: [audit, ...prev.auditLogs],
      };
    });
  };

  const adminSetCampaignStatus = (campaignId: string, status: Campaign['status'], reason?: string) => {
    supabaseDataService.updateRecord('campaigns', campaignId, { status });
    const targetCamp = state.campaigns.find((c) => c.id === campaignId);
    const audit = logAuditAction(`Campaign Status: ${status.toUpperCase()}`, 'campaign', campaignId, targetCamp?.title, reason);

    setState((prev) => ({
      ...prev,
      campaigns: prev.campaigns.map((c) => (c.id === campaignId ? { ...c, status } : c)),
      auditLogs: [audit, ...prev.auditLogs],
    }));

    if (targetCamp) {
      triggerPushNotification({
        userId: targetCamp.brandId,
        title: status === 'active' ? 'Campaign Approved! 🚀' : `Campaign Status ${status.toUpperCase()}`,
        body: status === 'active' ? `Your campaign brief '${targetCamp.title}' is now live for creators!` : `Campaign status changed to ${status}.`,
        type: status === 'active' ? 'campaign_approved' : 'campaign_rejected',
        payload: { screen: 'CampaignDetails', targetId: campaignId },
      });
    }
  };

  const adminDeleteCampaign = (campaignId: string, reason?: string) => {
    supabaseDataService.deleteRecord('campaigns', campaignId);
    const targetCamp = state.campaigns.find((c) => c.id === campaignId);
    const audit = logAuditAction('Delete Campaign Brief', 'campaign', campaignId, targetCamp?.title, reason);

    setState((prev) => ({
      ...prev,
      campaigns: prev.campaigns.filter((c) => c.id !== campaignId),
      auditLogs: [audit, ...prev.auditLogs],
    }));
  };

  const adminForceCompleteCampaign = (campaignId: string, reason?: string) => {
    const targetCamp = state.campaigns.find((c) => c.id === campaignId);
    const audit = logAuditAction('Force Complete Campaign', 'campaign', campaignId, targetCamp?.title, reason);

    setState((prev) => ({
      ...prev,
      campaigns: prev.campaigns.map((c) => (c.id === campaignId ? { ...c, status: 'completed' } : c)),
      auditLogs: [audit, ...prev.auditLogs],
    }));
  };

  const adminForceCancelCampaign = (campaignId: string, reason?: string) => {
    const targetCamp = state.campaigns.find((c) => c.id === campaignId);
    const audit = logAuditAction('Force Cancel Campaign', 'campaign', campaignId, targetCamp?.title, reason);

    setState((prev) => ({
      ...prev,
      campaigns: prev.campaigns.map((c) => (c.id === campaignId ? { ...c, status: 'rejected' } : c)),
      auditLogs: [audit, ...prev.auditLogs],
    }));

    if (targetCamp) {
      triggerPushNotification({
        userId: targetCamp.brandId,
        title: 'Campaign Brief Rejected',
        body: `Your campaign '${targetCamp.title}' was rejected. Reason: ${reason || 'Guidelines policy'}`,
        type: 'campaign_rejected',
        payload: { screen: 'CampaignDetails', targetId: campaignId },
      });
    }
  };

  const adminReleaseEscrow = (campaignId: string, type: 'full' | 'partial' | 'refund', amount?: number, reason?: string) => {
    const targetCamp = state.campaigns.find((c) => c.id === campaignId);
    const audit = logAuditAction(`Escrow Action: ${type.toUpperCase()}`, 'campaign', campaignId, targetCamp?.title, reason);

    setState((prev) => ({
      ...prev,
      campaigns: prev.campaigns.map((c) => {
        if (c.id !== campaignId) return c;
        return {
          ...c,
          escrowStatus: type === 'refund' ? 'refunded' : type === 'partial' ? 'partially_released' : 'released',
        };
      }),
      auditLogs: [audit, ...prev.auditLogs],
    }));
  };

  const adminProcessWithdrawal = (withdrawalId: string, action: WithdrawalRequest['status'], notes?: string, reason?: string) => {
    supabaseDataService.updateRecord('withdrawals', withdrawalId, { status: action, adminNotes: notes });
    const targetReq = state.withdrawals.find((w) => w.id === withdrawalId);
    const audit = logAuditAction(`Withdrawal ${action.toUpperCase()}`, 'withdrawal', withdrawalId, targetReq?.userName, reason);

    setState((prev) => {
      let updatedWallets = prev.wallets;
      if (targetReq && action === 'rejected') {
        // Refund back to user's available balance if rejected
        const userWallet = prev.wallets[targetReq.userId] || {
          userId: targetReq.userId,
          availableBalance: 0,
          pendingBalance: 0,
          totalEarned: 0,
          totalSpent: 0,
          escrowHold: 0,
          isFrozen: false,
        };
        updatedWallets = {
          ...prev.wallets,
          [targetReq.userId]: {
            ...userWallet,
            availableBalance: userWallet.availableBalance + targetReq.amount,
          },
        };
      }

      const updatedTxs = prev.transactions.map((tx) => {
        if (tx.referenceId === withdrawalId) {
          return {
            ...tx,
            status: (action === 'approved' || action === 'completed' ? 'completed' : action === 'rejected' ? 'rejected' : 'pending') as any,
          };
        }
        return tx;
      });

      return {
        ...prev,
        wallets: updatedWallets,
        withdrawals: prev.withdrawals.map((w) => {
          if (w.id !== withdrawalId) return w;
          return {
            ...w,
            status: action,
            adminNotes: notes || w.adminNotes,
            resolvedAt: new Date().toISOString(),
          };
        }),
        transactions: updatedTxs,
        auditLogs: [audit, ...prev.auditLogs],
      };
    });

    if (targetReq) {
      triggerPushNotification({
        userId: targetReq.userId,
        title: action === 'approved' || action === 'completed' ? 'Withdrawal Approved! 💸' : 'Withdrawal Request Update',
        body: action === 'approved' || action === 'completed'
          ? `Your payout of ₹${targetReq.amount} via ${targetReq.method} was approved and disbursed.`
          : `Your withdrawal request for ₹${targetReq.amount} was ${action}. Note: ${notes || 'Contact support'}`,
        type: action === 'approved' || action === 'completed' ? 'withdrawal_approved' : 'withdrawal_rejected',
        payload: { screen: 'WithdrawalDetails', targetId: withdrawalId },
      });
    }
  };

  const adminProcessDeposit = (depositId: string, action: DepositRequest['status'], reason?: string) => {
    supabaseDataService.updateRecord('deposits', depositId, { status: action, adminNotes: reason });
    const targetDep = state.deposits.find((d) => d.id === depositId);
    const audit = logAuditAction(`Deposit ${action.toUpperCase()}`, 'deposit', depositId, targetDep?.brandName, reason);

    setState((prev) => {
      let updatedWallets = prev.wallets;
      if (targetDep && action === 'approved') {
        const brandWallet = prev.wallets[targetDep.brandId] || {
          userId: targetDep.brandId,
          availableBalance: 0,
          pendingBalance: 0,
          totalEarned: 0,
          totalSpent: 0,
          escrowHold: 0,
          isFrozen: false,
        };

        updatedWallets = {
          ...prev.wallets,
          [targetDep.brandId]: {
            ...brandWallet,
            availableBalance: brandWallet.availableBalance + targetDep.amount,
          },
        };
      }

      const updatedTxs = prev.transactions.map((tx) => {
        if (tx.referenceId === depositId || (targetDep && tx.referenceId === targetDep.transactionRef)) {
          return {
            ...tx,
            status: (action === 'approved' ? 'completed' : action === 'rejected' ? 'rejected' : 'pending') as any,
          };
        }
        return tx;
      });

      return {
        ...prev,
        wallets: updatedWallets,
        deposits: prev.deposits.map((d) => {
          if (d.id !== depositId) return d;
          return {
            ...d,
            status: action,
            processedAt: new Date().toISOString(),
          };
        }),
        transactions: updatedTxs,
        auditLogs: [audit, ...prev.auditLogs],
      };
    });

    if (targetDep) {
      triggerPushNotification({
        userId: targetDep.brandId,
        title: action === 'approved' ? 'Deposit Confirmed! 💰' : 'Deposit Update',
        body: action === 'approved'
          ? `₹${targetDep.amount} deposit was approved and added to your wallet balance.`
          : `Deposit transaction ${targetDep.transactionRef} was rejected.`,
        type: action === 'approved' ? 'deposit_approved' : 'deposit_rejected',
        payload: { screen: 'Wallet', targetId: depositId },
      });
    }
  };

  const adminProcessDispute = (disputeId: string, action: DisputeReport['status'], notes?: string) => {
    supabaseDataService.updateRecord('disputes', disputeId, { status: action, adminNotes: notes });
    const targetDisp = state.disputes.find((d) => d.id === disputeId);
    const audit = logAuditAction(`Dispute: ${action.toUpperCase()}`, 'report', disputeId, targetDisp?.targetTitle, notes);

    setState((prev) => ({
      ...prev,
      disputes: prev.disputes.map((d) => {
        if (d.id !== disputeId) return d;
        return {
          ...d,
          status: action,
          adminNotes: notes || d.adminNotes,
          resolvedAt: new Date().toISOString(),
        };
      }),
      auditLogs: [audit, ...prev.auditLogs],
    }));
  };

  const adminProcessKycDoc = (docId: string, action: 'verified' | 'rejected', rejectionReason?: string) => {
    supabaseDataService.updateRecord('kyc_documents', docId, { status: action, rejectionReason });
    const targetDoc = state.kycDocuments.find((k) => k.id === docId);
    const audit = logAuditAction(`KYC ${action.toUpperCase()}`, 'user', docId, targetDoc?.userName, rejectionReason);

    setState((prev) => ({
      ...prev,
      kycDocuments: prev.kycDocuments.map((k) => {
        if (k.id !== docId) return k;
        return {
          ...k,
          status: action,
          verifiedAt: action === 'verified' ? new Date().toISOString() : undefined,
          rejectionReason: action === 'rejected' ? rejectionReason : undefined,
        };
      }),
      auditLogs: [audit, ...prev.auditLogs],
    }));

    if (targetDoc) {
      triggerPushNotification({
        userId: targetDoc.userId,
        title: action === 'verified' ? 'KYC Approved! 🛡️' : 'KYC Re-upload Required ⚠️',
        body: action === 'verified'
          ? `Your ${targetDoc.documentType.toUpperCase()} document has been verified successfully.`
          : `KYC document was rejected. Reason: ${rejectionReason || 'Document illegible'}`,
        type: action === 'verified' ? 'kyc_approved' : 'kyc_rejected',
        payload: { screen: 'KYCStatus', targetId: docId },
      });
    }
  };

  const adminUpdateSystemSettings = (newSettings: Partial<SystemSettings>, reason?: string) => {
    const audit = logAuditAction('Update System Settings', 'settings', 'system_config', 'Platform Settings', reason);

    setState((prev) => ({
      ...prev,
      systemSettings: { ...prev.systemSettings, ...newSettings },
      auditLogs: [audit, ...prev.auditLogs],
    }));
  };

  const adminSendBroadcast = (title: string, message: string, targetAudience: string) => {
    const audit = logAuditAction(`Broadcast: ${title}`, 'system', targetAudience, `Audience: ${targetAudience}`);

    const newNotif: AppNotification = {
      id: `notif_${Date.now()}`,
      userId: 'all',
      title: `[BROADCAST] ${title}`,
      body: message,
      type: 'admin_broadcast',
      payload: { screen: 'AdminMessage' },
      isRead: false,
      deliveryStatus: 'delivered',
      createdAt: new Date().toISOString(),
    };

    setState((prev) => ({
      ...prev,
      notifications: [newNotif, ...prev.notifications],
      auditLogs: [audit, ...prev.auditLogs],
    }));

    triggerPushNotification({
      userId: 'all',
      title: `[BROADCAST] ${title}`,
      body: message,
      type: 'admin_broadcast',
      payload: { screen: 'AdminMessage' },
    });
  };

  // STORE & SUBSCRIPTIONS MODULE IMPLEMENTATION
  const createProduct = async (data: Omit<StoreProduct, 'id' | 'rating' | 'salesCount' | 'viewsCount' | 'publishDate'>) => {
    const newProduct: StoreProduct = {
      ...data,
      id: `prod_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      rating: 5.0,
      salesCount: 0,
      viewsCount: 1,
      publishDate: new Date().toISOString(),
    };
    setState((prev) => ({
      ...prev,
      products: [newProduct, ...(prev.products || [])],
    }));
    
    // Persist to DB
    try {
      await supabaseDataService.createProduct(newProduct);
    } catch (err) {
      console.warn('Failed to save product to DB', err);
    }
  };

  const updateProduct = (productId: string, updates: Partial<StoreProduct>) => {
    supabaseDataService.updateRecord('products', productId, updates);
    setState((prev) => ({
      ...prev,
      products: (prev.products || []).map((p) => (p.id === productId ? { ...p, ...updates } : p)),
    }));
  };

  const deleteProduct = (productId: string) => {
    supabaseDataService.deleteRecord('products', productId);
    setState((prev) => ({
      ...prev,
      products: (prev.products || []).filter((p) => p.id !== productId),
    }));
  };

  const addToCart = (product: StoreProduct, quantity: number = 1, selectedColor?: string, selectedSize?: string) => {
    setState((prev) => {
      const currentCart = prev.cart || [];
      const existingIndex = currentCart.findIndex(
        (ci) => ci.productId === product.id && ci.selectedColor === selectedColor && ci.selectedSize === selectedSize
      );
      if (existingIndex > -1) {
        const updatedCart = [...currentCart];
        updatedCart[existingIndex].quantity += quantity;
        return { ...prev, cart: updatedCart };
      } else {
        return {
          ...prev,
          cart: [...currentCart, { productId: product.id, product, quantity, selectedColor, selectedSize }],
        };
      }
    });
  };

  const removeFromCart = (productId: string) => {
    setState((prev) => ({
      ...prev,
      cart: (prev.cart || []).filter((ci) => ci.productId !== productId),
    }));
  };

  const clearCart = () => {
    setState((prev) => ({ ...prev, cart: [] }));
  };

  const checkoutOrder = (params: {
    items: { product: StoreProduct; quantity: number; selectedColor?: string; selectedSize?: string }[];
    shippingAddress?: ShippingAddress;
    paymentMethod: string;
  }): { success: boolean; orderId: string; message: string } => {
    const orderId = `ord_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const orderItems: StoreOrderItem[] = params.items.map((it) => ({
      productId: it.product.id,
      productTitle: it.product.title,
      productType: it.product.productType,
      coverImage: it.product.coverImage,
      price: it.product.price,
      quantity: it.quantity,
      selectedColor: it.selectedColor,
      selectedSize: it.selectedSize,
      downloadUrl: it.product.downloadUrl,
      driveUrl: it.product.driveUrl,
      licenseKey: it.product.licenseKey,
    }));

    const totalAmount = params.items.reduce((sum, it) => sum + it.product.price * it.quantity, 0);
    const primaryType = params.items[0]?.product.productType || 'digital_product';
    const isDigital = primaryType === 'digital_product' || primaryType === 'free_resource';

    const newOrder: StoreOrder = {
      id: orderId,
      userId: currentUser?.id || "",
      userName: currentUser.name,
      userEmail: currentUser.email,
      items: orderItems,
      totalAmount,
      productType: primaryType,
      status: isDigital ? 'unlocked' : 'pending',
      shippingAddress: params.shippingAddress,
      paymentMethod: params.paymentMethod,
      transactionRef: `TXN_STORE_${Date.now()}`,
      createdAt: new Date().toISOString(),
      unlockedAt: isDigital ? new Date().toISOString() : undefined,
    };

    setState((prev) => {
      const updatedProducts = (prev.products || []).map((p) => {
        const purchased = params.items.find((it) => it.product.id === p.id);
        if (purchased) {
          return { ...p, salesCount: (p.salesCount || 0) + purchased.quantity };
        }
        return p;
      });

      return {
        ...prev,
        orders: [newOrder, ...(prev.orders || [])],
        products: updatedProducts,
        cart: [],
      };
    });

    return {
      success: true,
      orderId,
      message: isDigital
        ? 'Order completed! Digital product unlocked in My Purchases.'
        : 'Order placed successfully! Track status in My Purchases.',
    };
  };

  const subscribeToPlan = (planId: string): { success: boolean; message: string } => {
    const plan = (state.subscriptionPlans || []).find((p) => p.id === planId);
    if (!plan) return { success: false, message: 'Subscription plan not found.' };

    const startDate = new Date();
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 30);

    const newSub: UserSubscription = {
      id: `sub_${Date.now()}`,
      userId: currentUser?.id || "",
      planId: plan.id,
      planName: plan.name,
      startDate: startDate.toISOString(),
      expiryDate: expiryDate.toISOString(),
      status: 'active',
    };

    setState((prev) => ({
      ...prev,
      userSubscriptions: [newSub, ...(prev.userSubscriptions || []).filter((s) => s.userId !== currentUser.id)],
    }));

    return { success: true, message: `Subscribed to ${plan.name} successfully!` };
  };

  const toggleWishlist = (productId: string) => {
    setState((prev) => {
      const wishlist = prev.wishlist || [];
      const exists = wishlist.includes(productId);
      return {
        ...prev,
        wishlist: exists ? wishlist.filter((id) => id !== productId) : [...wishlist, productId],
      };
    });
  };

  const adminUpdateOrderStatus = (orderId: string, status: StoreOrder['status']) => {
    setState((prev) => ({
      ...prev,
      orders: (prev.orders || []).map((o) => (o.id === orderId ? { ...o, status } : o)),
    }));
  };

  return (
    <StoreContext.Provider
      value={{
        state,
        currentUser,
        currentWallet,
        userSettings,
        systemSettings: state.systemSettings,
        unreadNotificationsCount,
        requestNativePermission,
        markNotificationAsRead,
        markAllNotificationsAsRead,
        deleteNotification,
        refreshNotifications,
        triggerPushNotification,
        updateUserProfile,
        updateUserSettings,
        setRealSessionUser,
        switchRole,
        resetApp,
        createCampaign,
        applyToCampaign,
        updateApplicationStatus,
        submitDeliverable,
        adminApproveContentSubmission,
        adminRejectContentSubmission,
        adminDisburseCampaignPayout,
        requestWithdrawal,
        requestDeposit,
        depositBrandFunds,
        createReport,
        adminUpdateUserRole,
        adminSetUserStatus,
        adminVerifyUser,
        adminDeleteUser,
        adminResetUserKyc,
        adminResetUserPassword,
        adminAdjustUserWallet,
        adminSetWalletFreeze,
        adminSetCampaignStatus,
        adminDeleteCampaign,
        adminForceCompleteCampaign,
        adminForceCancelCampaign,
        adminReleaseEscrow,
        adminProcessWithdrawal,
        adminProcessDeposit,
        adminProcessDispute,
        adminProcessKycDoc,
        adminUpdateSystemSettings,
        adminSendBroadcast,

        // STORE & SUBSCRIPTION MODULE
        createProduct,
        updateProduct,
        deleteProduct,
        addToCart,
        removeFromCart,
        clearCart,
        checkoutOrder,
        subscribeToPlan,
        toggleWishlist,
        adminUpdateOrderStatus,
      }}
    >
      {/* Active In-App FCM Push Banner Overlay */}
      {activePushToast && (
        <div
          onClick={() => {
            deepLinkService.handleNotificationClick(activePushToast);
            setActivePushToast(null);
          }}
          className="fixed top-3 left-1/2 -translate-x-1/2 z-50 w-full max-w-sm px-3 animate-in fade-in slide-in-from-top duration-300 cursor-pointer"
        >
          <div className="bg-slate-900/95 text-white dark:bg-white/95 dark:text-slate-900 backdrop-blur-md p-3.5 rounded-2xl shadow-2xl border border-slate-700 dark:border-slate-200 flex items-start justify-between gap-3">
            <div className="flex items-start gap-2.5">
              <div className="p-2 rounded-xl bg-indigo-600 text-white shrink-0 mt-0.5">
                <Bell className="w-4 h-4" />
              </div>
              <div>
                <div className="flex items-center gap-1.5 mb-0.5">
                  <span className="text-xs font-bold leading-tight">{activePushToast.title}</span>
                  <span className="text-[9px] px-1.5 py-0.2 rounded font-bold bg-indigo-500 text-white">
                    NEW
                  </span>
                </div>
                <p className="text-[11px] opacity-90 line-clamp-2 leading-snug">
                  {activePushToast.body || activePushToast.message}
                </p>
              </div>
            </div>

            <button
              onClick={(e) => {
                e.stopPropagation();
                setActivePushToast(null);
              }}
              className="p-1 rounded-lg hover:bg-white/10 dark:hover:bg-slate-200 opacity-60 hover:opacity-100"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}

      {children}
      <NativePermissionModal isOpen={!!permissionRequest} request={permissionRequest} />
    </StoreContext.Provider>
  );
};

export const useStore = () => {
  const context = useContext(StoreContext);
  if (!context) {
    throw new Error('useStore must be used within a StoreProvider');
  }
  return context;
};
