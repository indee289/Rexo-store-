import { CardSkeleton } from '../common/Skeleton';
import { motion, AnimatePresence } from 'framer-motion';
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import React, { useState, useEffect } from 'react';
import { useStore } from '../../context/StoreContext';
import {
  UserProfile,
  UserRole,
  AdminSubRole,
  UserAccountStatus,
  Campaign,
  WithdrawalRequest,
  DepositRequest,
  DisputeReport,
  AuditLog,
} from '../../types';
import {
  ShieldCheck,
  Users,
  Briefcase,
  Wallet,
  DollarSign,
  AlertTriangle,
  Settings,
  FileText,
  Send,
  Search,
  Filter,
  CheckCircle2,
  XCircle,
  Clock,
  Lock,
  ArrowLeft,
  ChevronRight,
  Shield,
  Eye,
  UserPlus,
  RefreshCw,
  PlusCircle,
  MinusCircle,
  Ban,
  Slash,
  Trash2,
  TrendingUp,
  Download,
  AlertCircle,
  HelpCircle,
  Activity,
  Layers,
  BarChart2,
  Bell,
  X,
  Sliders,
  Check,
  ShoppingBag,
  Video,
} from 'lucide-react';
import { AdminShopCenter } from '../shop/AdminShopCenter';

interface AdminCenterViewProps {
  onBackToProfile: () => void;
}

export const AdminCenterView: React.FC<AdminCenterViewProps> = ({ onBackToProfile }) => {
  const {
    state,
    currentUser,
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
    adminApproveContentSubmission,
    adminRejectContentSubmission,
    adminDisburseCampaignPayout,
    adminProcessDispute,
    adminProcessKycDoc,
    adminUpdateSystemSettings,
    adminSendBroadcast,
  } = useStore();

  // Role check security
  const isSuperAdmin = currentUser.role === 'admin' && (currentUser.adminSubRole === 'super_admin' || !currentUser.adminSubRole);
  const isModerator = currentUser.role === 'admin' && currentUser.adminSubRole === 'moderator';
  const isFinanceAdmin = currentUser.role === 'admin' && currentUser.adminSubRole === 'finance_admin';

  if (currentUser.role !== 'admin') {
    return (
      <div className="min-h-screen bg-slate-50 dark:bg-slate-800/50 flex items-center justify-center p-4">
        <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full text-center space-y-4 border border-slate-200 shadow-lg">
          <div className="w-12 h-12 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center mx-auto">
            <Lock size={24} />
          </div>
          <h2 className="text-lg font-bold text-slate-900 dark:text-white">403 Access Denied</h2>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            You do not have administrative clearance to view the Protected Admin Center.
          </p>
          <button
            onClick={onBackToProfile}
            className="w-full py-2 bg-slate-900 text-white rounded-xl text-xs font-bold"
          >
            Return to Profile
          </button>
        </div>
      </div>
    );
  }

  // Active Admin Sub-Tab
  const [isLoading, setIsLoading] = useState(false);
  const [activeTab, setActiveTab] = useState<
    'dashboard' | 'users' | 'campaigns' | 'submissions' | 'deposits' | 'shop' | 'withdrawals' | 'disputes' | 'kyc' | 'wallets' | 'settings' | 'audit' | 'broadcast'
  >('dashboard');

  // Submission & Payout Modals State
    const handleTabSwitch = (tab: any) => {
    setIsLoading(true);
    setActiveTab(tab);
    setTimeout(() => setIsLoading(false), 500);
  };

  const [payoutRemarksModalAppId, setPayoutRemarksModalAppId] = useState<string | null>(null);
  const [payoutRemarksInput, setPayoutRemarksInput] = useState('Paid Out via Escrow - Cleared by Admin');
  const [rejectionReasonModalAppId, setRejectionReasonModalAppId] = useState<string | null>(null);
  const [rejectionReasonInput, setRejectionReasonInput] = useState('Reel content missing required brand tag/hashtag');
  const [submissionFilter, setSubmissionFilter] = useState<'all' | 'submitted' | 'approved' | 'paid' | 'rejected'>('all');

  // Search & Filter States
  const [userSearch, setUserSearch] = useState('');
  const [userRoleFilter, setUserRoleFilter] = useState<'all' | 'creator' | 'brand' | 'admin' | 'verified' | 'banned' | 'suspended'>('all');

  const [campaignSearch, setCampaignSearch] = useState('');
  const [campaignStatusFilter, setCampaignStatusFilter] = useState<'all' | 'active' | 'completed' | 'paused' | 'rejected'>('all');

  const [withdrawalFilter, setWithdrawalFilter] = useState<'all' | 'pending' | 'approved' | 'rejected' | 'held'>('pending');

  // Selected Item Modal Drawers
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [selectedCampaign, setSelectedCampaign] = useState<Campaign | null>(null);
  const [selectedWithdrawal, setSelectedWithdrawal] = useState<WithdrawalRequest | null>(null);

  // Form states
  const [actionReason, setActionReason] = useState('');
  const [walletAmount, setWalletAmount] = useState('');
  const [walletNote, setWalletNote] = useState('');
  const [broadcastTitle, setBroadcastTitle] = useState('');
  const [broadcastBody, setBroadcastBody] = useState('');
  const [broadcastTarget, setBroadcastTarget] = useState('all');

  // Toast feedback
  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3000);
  };

  // Filtered Lists
  const filteredUsers = state.users.filter((u) => {
    const matchesSearch =
      u.name.toLowerCase().includes(userSearch.toLowerCase()) ||
      u.username.toLowerCase().includes(userSearch.toLowerCase()) ||
      u.email.toLowerCase().includes(userSearch.toLowerCase()) ||
      u.id.toLowerCase().includes(userSearch.toLowerCase());

    if (!matchesSearch) return false;
    if (userRoleFilter === 'creator') return u.role === 'creator';
    if (userRoleFilter === 'brand') return u.role === 'brand';
    if (userRoleFilter === 'admin') return u.role === 'admin';
    if (userRoleFilter === 'verified') return u.isVerified;
    if (userRoleFilter === 'banned') return u.accountStatus === 'banned';
    if (userRoleFilter === 'suspended') return u.accountStatus === 'suspended';
    return true;
  });

  const filteredCampaigns = state.campaigns.filter((c) => {
    const matchesSearch = c.title.toLowerCase().includes(campaignSearch.toLowerCase()) || c.brandName.toLowerCase().includes(campaignSearch.toLowerCase());
    if (!matchesSearch) return false;
    if (campaignStatusFilter !== 'all') return c.status === campaignStatusFilter;
    return true;
  });

  const filteredWithdrawals = state.withdrawals.filter((w) => {
    if (withdrawalFilter !== 'all') return w.status === withdrawalFilter;
    return true;
  });

  // Analytics Metrics
  const totalUsers = state.users.length;
  const totalCreators = state.users.filter((u) => u.role === 'creator').length;
  const totalBrands = state.users.filter((u) => u.role === 'brand').length;
  const verifiedCreators = state.users.filter((u) => u.role === 'creator' && u.isVerified).length;
  const activeCampaigns = state.campaigns.filter((c) => c.status === 'active').length;
  const completedCampaigns = state.campaigns.filter((c) => c.status === 'completed').length;
  const pendingWithdrawalsCount = state.withdrawals.filter((w) => w.status === 'pending').length;
  const pendingWithdrawalsAmount = state.withdrawals
    .filter((w) => w.status === 'pending')
    .reduce((sum, w) => sum + w.amount, 0);
  const openDisputesCount = state.disputes.filter((d) => d.status === 'open' || d.status === 'investigating').length;
  const bannedUsersCount = state.users.filter((u) => u.accountStatus === 'banned' || u.accountStatus === 'suspended').length;
  
  // Mock Data for Admin Chart
  const adminChartData = [
    { name: 'Mon', users: 12, campaigns: 2, volume: 15000 },
    { name: 'Tue', users: 19, campaigns: 4, volume: 45000 },
    { name: 'Wed', users: 15, campaigns: 3, volume: 32000 },
    { name: 'Thu', users: 22, campaigns: 5, volume: 68000 },
    { name: 'Fri', users: 30, campaigns: 8, volume: 120000 },
    { name: 'Sat', users: 25, campaigns: 6, volume: 89000 },
    { name: 'Sun', users: 18, campaigns: 3, volume: 41000 },
  ];

  const totalEscrowHeld = state.campaigns.reduce((sum, c) => sum + (c.escrowAmount || 0), 0);

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-white dark:text-slate-100 font-sans transition-colors">
      {/* STICKY TOP HEADER */}
      <header className="sticky top-0 z-40 bg-white/95 dark:bg-slate-950/95 backdrop-blur-md border-b border-slate-200/80 dark:border-slate-800 px-4 py-3 shadow-2xs transition-colors">
        <div className="max-w-6xl mx-auto flex items-center justify-between gap-2">
          <div className="flex items-center gap-2 min-w-0">
            <button
              onClick={onBackToProfile}
              className="p-2 shrink-0 rounded-xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-50 transition-all active:scale-95"
              title="Return to Profile"
            >
              <ArrowLeft size={16} />
            </button>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight truncate">Admin</h1>
                <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-rose-100 text-rose-800 border border-rose-200 uppercase tracking-wider shrink-0 whitespace-nowrap hidden sm:inline-block">
                  {currentUser.adminSubRole?.replace('_', ' ') || 'SUPER ADMIN'}
                </span>
              </div>
              <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">Production Control & Escrow Operations</p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <span className="text-xs font-bold text-slate-600 dark:text-slate-400 hidden sm:inline">{currentUser.name}</span>
            <div className="w-8 h-8 rounded-full bg-slate-900 text-white flex items-center justify-center font-extrabold text-xs">
              SA
            </div>
          </div>
        </div>
      </header>

      {/* TOAST FEEDBACK */}
      {toastMsg && (
        <div className="fixed top-16 right-4 z-[60] bg-slate-900 text-white px-4 py-3 rounded-2xl shadow-xl text-xs font-bold flex items-center gap-2 animate-in fade-in slide-in-from-top-2">
          <CheckCircle2 size={16} className="text-emerald-400" />
          <span>{toastMsg}</span>
        </div>
      )}

      <div className="max-w-6xl mx-auto px-4 mt-4 space-y-5">
        {/* SUB-NAVIGATION PILL BAR */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 no-scrollbar text-xs font-bold">
          <button
            onClick={() => handleTabSwitch('dashboard')}
            className={`${activeTab === 'dashboard' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Dashboard
          </button>

          <button
            onClick={() => handleTabSwitch('users')}
            className={`${activeTab === 'users' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Users ({state.users.length})
          </button>

          <button
            onClick={() => handleTabSwitch('campaigns')}
            className={`${activeTab === 'campaigns' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Campaigns ({state.campaigns.length})
          </button>

          <button
            onClick={() => handleTabSwitch('submissions')}
            className={`relative ${activeTab === 'submissions' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Content Review ({state.applications.filter((a) => a.deliverableUrl || a.status === 'submitted').length})
            {state.applications.filter((a) => a.status === 'submitted').length > 0 && (
              <span className="ml-1.5 px-1.5 py-0.2 bg-amber-500 text-white text-[9px] rounded-full font-bold">
                {state.applications.filter((a) => a.status === 'submitted').length}
              </span>
            )}
          </button>

          <button
            onClick={() => setActiveTab('deposits')}
            className={`relative ${activeTab === 'deposits' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Deposit Requests ({state.deposits.length})
            {state.deposits.filter((d) => d.status === 'pending').length > 0 && (
              <span className="ml-1.5 px-1.5 py-0.2 bg-rose-500 text-white text-[9px] rounded-full font-bold">
                {state.deposits.filter((d) => d.status === 'pending').length}
              </span>
            )}
          </button>

          <button
            onClick={() => setActiveTab('shop')}
            className={`inline-flex items-center justify-center gap-1.5 transition-all active:scale-95 ${activeTab === 'shop' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0'}`}
          >
            <ShoppingBag size={14} /> Shop & Catalog
          </button>

          <button
            onClick={() => setActiveTab('withdrawals')}
            className={`relative ${activeTab === 'withdrawals' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Withdrawals & Escrow
            {pendingWithdrawalsCount > 0 && (
              <span className="ml-1.5 px-1.5 py-0.2 bg-rose-500 text-white text-[9px] rounded-full font-bold">
                {pendingWithdrawalsCount}
              </span>
            )}
          </button>

          <button
            onClick={() => setActiveTab('disputes')}
            className={`${activeTab === 'disputes' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Disputes ({state.disputes.length})
          </button>

          <button
            onClick={() => setActiveTab('kyc')}
            className={`${activeTab === 'kyc' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            KYC Queue ({state.kycDocuments.filter((k) => k.status === 'pending').length})
          </button>

          {isSuperAdmin && (
            <button
              onClick={() => setActiveTab('settings')}
              className={`${activeTab === 'settings' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
            >
              Platform Settings
            </button>
          )}

          <button
            onClick={() => setActiveTab('audit')}
            className={`${activeTab === 'audit' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Audit Logs ({state.auditLogs.length})
          </button>

          <button
            onClick={() => setActiveTab('broadcast')}
            className={`${activeTab === 'broadcast' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
          >
            Broadcast
          </button>
        </div>

        {/* ==================== 0. SHOP & CATALOG TAB ==================== */}
        {activeTab === 'shop' && (
          <AdminShopCenter isEmbedded={true} />
        )}

        {/* ==================== 1. DASHBOARD TAB ==================== */}
        {activeTab === 'dashboard' && (
          <div className="space-y-4">

            {/* PLATFORM ACTIVITY CHART */}
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">Platform Volume (7 Days)</h3>
              </div>
              <div className="h-56 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={adminChartData} margin={{ top: 10, right: 0, left: -20, bottom: 0 }} barSize={12}>
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#94a3b8' }} />
                    <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#94a3b8' }} tickFormatter={(value) => `₹${value/1000}k`} />
                    <Tooltip 
                      contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', fontSize: '12px', fontWeight: 'bold' }}
                      cursor={{fill: 'transparent'}}
                    />
                    <Bar dataKey="volume" fill="#6366f1" radius={[4, 4, 4, 4]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-1">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Total Users
                </span>
                <span className="text-xl font-bold text-slate-900 dark:text-white block">{totalUsers}</span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400 font-medium">
                  {totalCreators} Creators • {totalBrands} Brands
                </span>
              </div>

              <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-1">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Active Campaigns
                </span>
                <span className="text-xl font-bold text-indigo-600 block">{activeCampaigns}</span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400 font-medium">{completedCampaigns} Completed</span>
              </div>

              <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-1">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Pending Payouts
                </span>
                <span className="text-xl font-bold text-amber-600 block">₹{pendingWithdrawalsAmount.toLocaleString('en-IN')}</span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400 font-medium">{pendingWithdrawalsCount} Pending Requests</span>
              </div>

              <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-1">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Total Escrow Hold
                </span>
                <span className="text-xl font-bold text-emerald-600 block">₹{totalEscrowHeld.toLocaleString('en-IN')}</span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400 font-medium">Secured Escrow Funds</span>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Quick Actions Panel */}
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-3">
                <h3 className="text-xs font-bold text-slate-900 dark:text-white uppercase tracking-wider">
                  Admin Action Hub
                </h3>
                <div className="grid grid-cols-2 gap-2 text-xs font-bold">
                  <button
                    onClick={() => handleTabSwitch('users')}
                    className="p-3 bg-slate-50 dark:bg-slate-800/50 hover:bg-slate-100 dark:bg-slate-800 border border-slate-200/80 dark:border-slate-800 rounded-2xl text-left text-slate-800 dark:text-slate-200 transition-all"
                  >
                    Manage Users
                  </button>
                  <button
                    onClick={() => handleTabSwitch('campaigns')}
                    className="p-3 bg-slate-50 dark:bg-slate-800/50 hover:bg-slate-100 dark:bg-slate-800 border border-slate-200/80 dark:border-slate-800 rounded-2xl text-left text-slate-800 dark:text-slate-200 transition-all"
                  >
                    Manage Campaigns
                  </button>
                  <button
                    onClick={() => setActiveTab('withdrawals')}
                    className="p-3 bg-slate-50 dark:bg-slate-800/50 hover:bg-slate-100 dark:bg-slate-800 border border-slate-200/80 dark:border-slate-800 rounded-2xl text-left text-slate-800 dark:text-slate-200 transition-all"
                  >
                    Approve Payouts
                  </button>
                  <button
                    onClick={() => setActiveTab('broadcast')}
                    className="p-3 bg-slate-50 dark:bg-slate-800/50 hover:bg-slate-100 dark:bg-slate-800 border border-slate-200/80 dark:border-slate-800 rounded-2xl text-left text-slate-800 dark:text-slate-200 transition-all"
                  >
                    Send System Broadcast
                  </button>
                </div>
              </div>

              {/* Recent Audit Stream */}
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-xs font-bold text-slate-900 dark:text-white uppercase tracking-wider">
                    Recent Audit Stream
                  </h3>
                  <button
                    onClick={() => setActiveTab('audit')}
                    className="text-[10px] font-bold text-indigo-600 hover:underline"
                  >
                    View All
                  </button>
                </div>

                {state.auditLogs.length === 0 ? (
                  <p className="text-xs text-slate-400 italic">No admin actions recorded yet in session audit trail.</p>
                ) : (
                  <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
                    {state.auditLogs.slice(0, 5).map((log) => (
                      <div key={log.id} className="p-2.5 bg-slate-50 dark:bg-slate-800/50 rounded-xl text-xs border border-slate-100 flex items-center justify-between">
                        <div>
                          <strong className="font-extrabold text-slate-900 dark:text-white block">{log.action}</strong>
                          <span className="text-slate-500 dark:text-slate-400 font-medium">
                            By {log.adminName} • {log.targetName || log.targetId}
                          </span>
                        </div>
                        <span className="text-[10px] text-slate-400">{new Date(log.timestamp).toLocaleTimeString()}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* ==================== 2. USER MANAGEMENT TAB ==================== */}
        {activeTab === 'users' && (
          <div className="space-y-4">
            {/* Search & Role Filter Header */}
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-3">
              <div className="flex flex-col sm:flex-row gap-3">
                <div className="relative flex-1">
                  <Search size={16} className="absolute left-3.5 top-3.5 text-slate-400" />
                  <input
                    type="text"
                    placeholder="Search name, username, email, phone, ID..."
                    value={userSearch}
                    onChange={(e) => setUserSearch(e.target.value)}
                    className="w-full bg-[#EBF0F5] dark:bg-slate-900/90 border border-slate-200/60 dark:border-slate-800 rounded-2xl pl-10 pr-4 py-2.5 text-xs text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>

                <div className="flex items-center gap-1 overflow-x-auto text-xs font-bold no-scrollbar">
                  {(['all', 'creator', 'brand', 'admin', 'verified', 'banned', 'suspended'] as const).map((filter) => (
                    <button
                      key={filter}
                      onClick={() => setUserRoleFilter(filter)}
                      className={`${userRoleFilter === filter ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
                    >
                      {filter}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Users List Table */}
            {filteredUsers.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <Users size={32} className="mx-auto text-slate-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">No matching users found</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400">Try adjusting your search criteria or user filters.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {filteredUsers.map((user) => (
                  <div key={user.id} className="p-4 flex items-center justify-between gap-3 hover:bg-slate-50/80 transition-all text-xs">
                    <div className="flex items-center gap-2 min-w-0">
                      <img src={user.avatar} alt={user.name} className="w-10 h-10 rounded-xl object-cover border border-slate-200" />
                      <div>
                        <div className="flex items-center gap-1.5">
                          <strong className="font-extrabold text-slate-900 dark:text-white">{user.name}</strong>
                          {user.isVerified && <CheckCircle2 size={13} className="text-indigo-600" />}
                          <span
                            className={`text-[9px] font-bold px-2 py-0.2 rounded-full uppercase border ${
                              user.role === 'admin'
                                ? 'bg-rose-50 text-rose-700 border-rose-200'
                                : user.role === 'creator'
                                ? 'bg-indigo-50 text-indigo-700 border-indigo-200'
                                : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            }`}
                          >
                            {user.role}
                          </span>

                          {user.accountStatus && user.accountStatus !== 'active' && (
                            <span className="text-[9px] font-bold px-2 py-0.2 rounded-full bg-slate-900 text-white uppercase">
                              {user.accountStatus}
                            </span>
                          )}
                        </div>
                        <span className="text-slate-400 text-[11px] font-medium">
                          @{user.username} • {user.email}
                        </span>
                      </div>
                    </div>

                    <button
                      onClick={() => setSelectedUser(user)}
                      className="px-3.5 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 font-extrabold text-xs transition-all active:scale-95 shadow-xs"
                    >
                      Manage
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== 3. CAMPAIGN MANAGEMENT TAB ==================== */}
        {activeTab === 'campaigns' && (
          <div className="space-y-4">
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs flex flex-col sm:flex-row gap-3">
              <div className="relative flex-1">
                <Search size={16} className="absolute left-3.5 top-3.5 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search campaign title or brand name..."
                  value={campaignSearch}
                  onChange={(e) => setCampaignSearch(e.target.value)}
                  className="w-full bg-[#EBF0F5] dark:bg-slate-900/90 border border-slate-200/60 dark:border-slate-800 rounded-2xl pl-10 pr-4 py-2.5 text-xs text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div className="flex items-center gap-1 text-xs font-bold">
                {(['all', 'active', 'completed', 'paused', 'rejected'] as const).map((status) => (
                  <button
                    key={status}
                    onClick={() => setCampaignStatusFilter(status)}
                    className={`${campaignStatusFilter === status ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
                  >
                    {status}
                  </button>
                ))}
              </div>
            </div>

            {filteredCampaigns.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <Briefcase size={32} className="mx-auto text-slate-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">No campaigns found</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400">There are no campaigns matching the current filter.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {filteredCampaigns.map((camp) => (
                  <div key={camp.id} className="p-4 flex items-center justify-between gap-3 hover:bg-slate-50/80 transition-all text-xs">
                    <div className="min-w-0">
              <div className="flex items-center gap-2">
                        <strong className="font-extrabold text-slate-900 dark:text-white text-sm">{camp.title}</strong>
                        <span
                          className={`text-[9px] font-extrabold px-2 py-0.5 rounded-full uppercase ${
                            camp.status === 'active'
                              ? 'bg-emerald-100 text-emerald-800'
                              : camp.status === 'completed'
                              ? 'bg-blue-100 text-blue-800'
                              : 'bg-rose-100 text-rose-800'
                          }`}
                        >
                          {camp.status}
                        </span>
                      </div>
                      <p className="text-slate-500 dark:text-slate-400 text-[11px] font-medium mt-0.5">
                        Brand: {camp.brandName} • Budget: ₹{camp.totalBudget.toLocaleString('en-IN')} • Payout/Creator: ₹
                        {camp.payoutPerCreator.toLocaleString('en-IN')}
                      </p>
                    </div>

                    <button
                      onClick={() => setSelectedCampaign(camp)}
                      className="px-3.5 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 font-extrabold text-xs transition-all active:scale-95 shadow-xs shrink-0"
                    >
                      Control Brief
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== CONTENT SUBMISSIONS TAB ==================== */}
        {activeTab === 'submissions' && (
          <div className="space-y-4">
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs flex items-center justify-between flex-wrap gap-2 text-xs font-bold">
              <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar">
                {(['all', 'submitted', 'approved', 'paid', 'rejected'] as const).map((filter) => (
                  <button
                    key={filter}
                    onClick={() => setSubmissionFilter(filter)}
                    className={`inline-flex items-center justify-center gap-1.5 transition-all active:scale-95 ${activeTab === 'shop' ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0'}`}
                  >
                    {filter === 'submitted' ? 'In Review' : filter}
                  </button>
                ))}
              </div>
              <span className="text-slate-400 text-[11px] font-medium">
                Review Reel/Story links submitted by creators
              </span>
            </div>

            {state.applications.filter((a) => {
              if (submissionFilter === 'all') return a.deliverableUrl || a.status === 'submitted';
              return a.status === submissionFilter;
            }).length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <Video size={32} className="mx-auto text-slate-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">No content submissions found</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">No creator submissions match this status filter.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {state.applications
                  .filter((a) => {
                    if (submissionFilter === 'all') return a.deliverableUrl || a.status === 'submitted';
                    return a.status === submissionFilter;
                  })
                  .map((app) => (
                    <div key={app.id} className="p-4 space-y-3 text-xs">
                      <div className="flex items-center justify-between gap-2 flex-wrap">
                        <div className="min-w-0">
              <div className="flex items-center gap-2">
                            <strong className="font-extrabold text-slate-900 dark:text-white text-sm">{app.creatorName}</strong>
                            <span className="text-[10px] text-slate-400 font-mono">(@{app.creatorHandle})</span>
                            <span
                              className={`text-[9px] font-bold px-2 py-0.5 rounded-full uppercase ${
                                app.status === 'submitted'
                                  ? 'bg-amber-100 text-amber-800'
                                  : app.status === 'approved'
                                  ? 'bg-indigo-100 text-indigo-800'
                                  : app.status === 'paid'
                                  ? 'bg-emerald-100 text-emerald-800'
                                  : 'bg-rose-100 text-rose-800'
                              }`}
                            >
                              {app.status}
                            </span>
                          </div>
                          <p className="text-slate-500 dark:text-slate-400 text-[11px] font-medium mt-0.5">
                            Campaign: <strong className="text-slate-800 dark:text-slate-200">{app.campaignTitle}</strong> • Brand: {app.brandName} • Payout Fee: ₹{(app.feeRequested || 3500).toLocaleString('en-IN')}
                          </p>
                        </div>

                        {/* SUBMISSION DELIVERABLE URL BUTTON */}
                        {app.deliverableUrl ? (
                          <a
                            href={app.deliverableUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="px-3 py-1.5 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 font-bold rounded-xl text-xs flex items-center gap-1 border border-indigo-200"
                          >
                            View Reel/Story Post ↗
                          </a>
                        ) : (
                          <span className="text-slate-400 text-[11px] italic">No URL provided</span>
                        )}
                      </div>

                      {/* REJECTION REASON DISPLAY */}
                      {app.status === 'rejected' && app.rejectionReason && (
                        <div className="p-2.5 bg-rose-50 border border-rose-200 rounded-xl text-xs text-rose-800 font-medium">
                          <strong>Rejection Remark:</strong> {app.rejectionReason}
                        </div>
                      )}

                      {/* PAID OUT REMARKS DISPLAY */}
                      {app.status === 'paid' && (
                        <div className="p-2.5 bg-emerald-50 border border-emerald-200 rounded-xl text-xs text-emerald-800 font-medium flex items-center justify-between">
                          <span><strong>Paid Out Remarks:</strong> {app.payoutRemarks || 'Paid Out via Escrow'}</span>
                          <span className="font-extrabold text-emerald-700">₹{(app.feeRequested || 3500).toLocaleString('en-IN')}</span>
                        </div>
                      )}

                      {/* ADMIN ACTION BUTTONS */}
                      <div className="flex items-center gap-2 pt-1 border-t border-slate-100">
                        {app.status === 'submitted' && (
                          <>
                            <button
                              onClick={() => {
                                adminApproveContentSubmission(app.id);
                                showToast('Content Approved! Ready for Payout.');
                              }}
                              className="px-3.5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-extrabold text-xs transition-all active:scale-95 shadow-xs"
                            >
                              Approve Content
                            </button>
                            <button
                              onClick={() => {
                                const reason = prompt('Enter rejection reason for creator:', 'Reel missing required brand tag or hashtag');
                                if (reason) {
                                  adminRejectContentSubmission(app.id, reason);
                                  showToast('Submission Rejected');
                                }
                              }}
                              className="px-3.5 py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-extrabold rounded-xl text-xs active:scale-95"
                            >
                              Reject Submission
                            </button>
                          </>
                        )}

                        {(app.status === 'approved' || app.status === 'submitted') && (
                          <button
                            onClick={() => {
                              const remarks = prompt('Enter payout remarks / reference number:', 'Paid Out via Escrow - Cleared by Admin');
                              if (remarks) {
                                adminDisburseCampaignPayout(app.id, remarks);
                                showToast('Campaign Payout Disbursed!');
                              }
                            }}
                            className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold rounded-xl text-xs active:scale-95 flex items-center gap-1 ml-auto"
                          >
                            Disburse Payout & Mark Paid Out
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== DEPOSITS QUEUE TAB ==================== */}
        {activeTab === 'deposits' && (
          <div className="space-y-4">
            {state.deposits.filter(d => d.status === 'pending').length > 0 && (
              <div className="bg-indigo-50 border border-indigo-200 rounded-2xl p-3 flex items-center justify-between">
                <span className="text-xs font-bold text-indigo-900">
                  {state.deposits.filter(d => d.status === 'pending').length} Pending Deposits Awaiting Clearance
                </span>
                <button
                  onClick={() => {
                    const pendingIds = state.deposits.filter(d => d.status === 'pending').map(d => d.id);
                    pendingIds.forEach(id => adminProcessDeposit(id, 'approved', 'Bulk cleared by admin'));
                    showToast(`Bulk approved ${pendingIds.length} deposit requests!`);
                  }}
                  className="px-3.5 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-extrabold rounded-xl shadow-xs transition-all active:scale-95"
                >
                  Bulk Approve All Pending
                </button>
              </div>
            )}

            {state.deposits.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <CheckCircle2 size={32} className="mx-auto text-emerald-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">No deposit requests</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">All brand deposit requests have been processed.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {state.deposits.map((dep) => (
                  <div key={dep.id} className="p-4 flex items-center justify-between gap-3 text-xs flex-wrap">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <strong className="font-bold text-slate-900 dark:text-white text-sm">₹{dep.amount.toLocaleString('en-IN')}</strong>
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 uppercase">
                          {dep.paymentMethod}
                        </span>
                        <span
                          className={`text-[9px] font-bold px-2 py-0.5 rounded-full uppercase ${
                            dep.status === 'pending'
                              ? 'bg-amber-100 text-amber-800'
                              : dep.status === 'approved'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-rose-100 text-rose-800'
                          }`}
                        >
                          {dep.status}
                        </span>
                      </div>
                      <p className="text-slate-500 dark:text-slate-400 text-[11px] font-medium">
                        Brand: <strong className="text-slate-800 dark:text-slate-200">{dep.brandName}</strong> • UTR Ref: <span className="font-mono font-bold text-slate-900 dark:text-white">{dep.transactionRef}</span>
                      </p>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      {dep.proofScreenshotUrl && (
                        <a
                          href={dep.proofScreenshotUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="px-3 py-1.5 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-800 dark:text-slate-200 font-bold rounded-xl text-xs flex items-center gap-1"
                        >
                          Proof Screenshot ↗
                        </a>
                      )}

                      {dep.status === 'pending' && (
                        <>
                          <button
                            onClick={() => {
                              adminProcessDeposit(dep.id, 'approved');
                              showToast(`Deposit Approved! ₹${dep.amount.toLocaleString('en-IN')} credited to ${dep.brandName}`);
                            }}
                            className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold rounded-xl text-xs active:scale-95"
                          >
                            Confirm & Credit Deposit
                          </button>
                          <button
                            onClick={() => {
                              adminProcessDeposit(dep.id, 'rejected');
                              showToast('Deposit Rejected');
                            }}
                            className="px-3.5 py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-extrabold rounded-xl text-xs active:scale-95"
                          >
                            Reject
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== 4. WITHDRAWALS & ESCROW TAB ==================== */}
        {activeTab === 'withdrawals' && (
          <div className="space-y-4">
            <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 border border-slate-200/80 dark:border-slate-800 shadow-2xs flex items-center gap-2 text-xs font-bold overflow-x-auto">
              {(['pending', 'approved', 'rejected', 'held', 'all'] as const).map((filter) => (
                <button
                  key={filter}
                  onClick={() => setWithdrawalFilter(filter)}
                  className={`px-3 py-2 rounded-xl capitalize whitespace-nowrap transition-all ${
                    withdrawalFilter === filter ? 'bg-slate-900 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  {filter}
                </button>
              ))}
            </div>

            {filteredWithdrawals.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <Wallet size={32} className="mx-auto text-slate-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">No withdrawal requests found</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400">No creator payout requests exist under this status filter.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {filteredWithdrawals.map((req) => (
                  <div key={req.id} className="p-4 flex items-center justify-between gap-3 text-xs">
                    <div className="min-w-0">
              <div className="flex items-center gap-2">
                        <strong className="font-extrabold text-slate-900 dark:text-white">₹{req.amount.toLocaleString('en-IN')}</strong>
                        <span className="text-[10px] font-bold px-2 py-0.2 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 uppercase">
                          {req.method}
                        </span>
                        <span
                          className={`text-[9px] font-bold px-2 py-0.2 rounded-full uppercase ${
                            req.status === 'pending'
                              ? 'bg-amber-100 text-amber-800'
                              : req.status === 'approved'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-rose-100 text-rose-800'
                          }`}
                        >
                          {req.status}
                        </span>
                      </div>
                      <p className="text-slate-500 dark:text-slate-400 text-[11px] font-medium mt-0.5">
                        User: {req.userName} • ID: {req.userId}
                      </p>
                    </div>

                    {isFinanceAdmin || isSuperAdmin ? (
                      <div className="flex items-center gap-1.5 shrink-0">
                        {req.status === 'pending' && (
                          <>
                            <button
                              onClick={() => {
                                adminProcessWithdrawal(req.id, 'approved', 'Clearance approved by Admin');
                                showToast('Withdrawal Approved');
                              }}
                              className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold rounded-xl text-xs active:scale-95"
                            >
                              Approve
                            </button>

                            <button
                              onClick={() => {
                                adminProcessWithdrawal(req.id, 'rejected', 'Verification mismatch');
                                showToast('Withdrawal Rejected');
                              }}
                              className="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-extrabold rounded-xl text-xs active:scale-95"
                            >
                              Reject
                            </button>
                          </>
                        )}
                      </div>
                    ) : (
                      <span className="text-[10px] text-slate-400 italic">Finance clearance restricted</span>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== 5. DISPUTES & REPORTS TAB ==================== */}
        {activeTab === 'disputes' && (
          <div className="space-y-4">
            {state.disputes.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <AlertTriangle size={32} className="mx-auto text-slate-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">No active disputes or reports</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">Platform compliance queue is clear.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {state.disputes.map((disp) => (
                  <div key={disp.id} className="p-4 space-y-2 text-xs">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="font-extrabold uppercase px-2 py-0.5 rounded-full bg-rose-100 text-rose-800 text-[9px]">
                          {disp.reasonType.replace('_', ' ')}
                        </span>
                        <strong className="font-bold text-slate-900 dark:text-white">{disp.targetTitle}</strong>
                      </div>
                      <span className="text-slate-400 text-[10px]">{new Date(disp.createdAt).toLocaleDateString()}</span>
                    </div>

                    <p className="text-slate-600 dark:text-slate-400 text-[11px]">{disp.description}</p>

                    <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                      <span className="text-[10px] text-slate-400 font-medium">Reported by: {disp.reporterName}</span>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => {
                            adminProcessDispute(disp.id, 'resolved', 'Resolved by Moderator');
                            showToast('Dispute Resolved');
                          }}
                          className="px-2.5 py-1 bg-emerald-600 text-white font-bold text-[10px] rounded-lg"
                        >
                          Resolve
                        </button>
                        <button
                          onClick={() => {
                            adminProcessDispute(disp.id, 'dismissed', 'Dismissed as invalid');
                            showToast('Dispute Dismissed');
                          }}
                          className="px-2.5 py-1 bg-slate-200 text-slate-700 dark:text-slate-300 font-bold text-[10px] rounded-lg"
                        >
                          Dismiss
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== 6. KYC VERIFICATION QUEUE ==================== */}
        {activeTab === 'kyc' && (
          <div className="space-y-4">
            {state.kycDocuments.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <CheckCircle2 size={32} className="mx-auto text-emerald-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">KYC queue is empty</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">No pending identity verification submissions.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {state.kycDocuments.map((doc) => (
                  <div key={doc.id} className="p-4 flex items-center justify-between text-xs">
                    <div>
                      <strong className="font-extrabold text-slate-900 dark:text-white block">{doc.userName}</strong>
                      <span className="text-slate-500 dark:text-slate-400 text-[11px]">
                        Doc: {doc.documentType.toUpperCase()} • Number: {doc.documentNumber}
                      </span>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      <button
                        onClick={() => {
                          adminProcessKycDoc(doc.id, 'verified');
                          showToast('KYC Approved');
                        }}
                        className="px-3 py-1.5 bg-emerald-600 text-white font-bold rounded-xl active:scale-95"
                      >
                        Approve
                      </button>
                      <button
                        onClick={() => {
                          adminProcessKycDoc(doc.id, 'rejected', 'Document mismatch');
                          showToast('KYC Rejected');
                        }}
                        className="px-3 py-1.5 bg-rose-600 text-white font-bold rounded-xl active:scale-95"
                      >
                        Reject
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== 7. PLATFORM SETTINGS ==================== */}
        {activeTab === 'settings' && isSuperAdmin && (
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4 text-xs font-bold">
            <h3 className="text-xs font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              System Settings & Rules
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-slate-700 dark:text-slate-300 mb-1">Platform Fee Commission (%)</label>
                <input
                  type="number"
                  value={state.systemSettings.platformCommissionRate * 100}
                  onChange={(e) =>
                    adminUpdateSystemSettings({ platformCommissionRate: Number(e.target.value) / 100 })
                  }
                  className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-200 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-slate-700 dark:text-slate-300 mb-1">Minimum Withdrawal (₹)</label>
                <input
                  type="number"
                  value={state.systemSettings.minimumWithdrawalAmount}
                  onChange={(e) =>
                    adminUpdateSystemSettings({ minimumWithdrawalAmount: Number(e.target.value) })
                  }
                  className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-200 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>
            </div>

            <button
              onClick={() => showToast('Platform settings updated!')}
              className="px-5 py-2.5 bg-slate-900 text-white rounded-xl font-bold active:scale-95"
            >
              Save Configuration
            </button>
          </div>
        )}

        {/* ==================== 8. AUDIT LOGS TAB ==================== */}
        {activeTab === 'audit' && (
          <div className="space-y-3">
            <div className="flex items-center justify-between bg-slate-50 dark:bg-slate-800/50 border border-slate-200 p-3 rounded-2xl">
              <span className="text-xs font-bold text-slate-800 dark:text-slate-200">
                Total Logs: {state.auditLogs.length}
              </span>
              <button
                onClick={() => {
                  window.open('/api/admin/audit-logs/export-csv', '_blank');
                  showToast('Exporting Audit Logs CSV...');
                }}
                className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold rounded-xl shadow-xs transition-all active:scale-95 flex items-center gap-1.5"
              >
                <Download size={14} />
                Export CSV
              </button>
            </div>

            {state.auditLogs.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200/80 dark:border-slate-800 text-center space-y-2">
                <FileText size={32} className="mx-auto text-slate-300" />
                <h3 className="text-xs font-bold text-slate-900 dark:text-white">No audit logs recorded</h3>
                <p className="text-[11px] text-slate-500 dark:text-slate-400">Every admin action will automatically log here.</p>
              </div>
            ) : (
              <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800 shadow-2xs">
                {state.auditLogs.map((log) => (
                  <div key={log.id} className="p-3.5 text-xs flex items-center justify-between">
                    <div>
                      <strong className="font-extrabold text-slate-900 dark:text-white block">{log.action}</strong>
                      <span className="text-slate-500 dark:text-slate-400 text-[11px]">
                        Admin: {log.adminName} ({log.adminRole}) • Target: {log.targetName || log.targetId}
                      </span>
                    </div>
                    <span className="text-[10px] text-slate-400 font-mono">
                      {new Date(log.timestamp).toLocaleString()}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================== 9. SYSTEM BROADCAST TAB ==================== */}
        {activeTab === 'broadcast' && (
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4 text-xs">
            <h3 className="text-xs font-bold text-slate-900 dark:text-white uppercase tracking-wider">
              Send System Broadcast
            </h3>

            <div className="space-y-3 font-bold">
              <div>
                <label className="block text-slate-700 dark:text-slate-300 mb-1">Target Audience</label>
                <div className="flex flex-wrap gap-1.5">
                  {[
                    { id: 'all', label: 'All Platform Users' },
                    { id: 'creators', label: 'Only Creators' },
                    { id: 'brands', label: 'Only Brands' },
                    { id: 'verified', label: 'Verified Users' },
                  ].map((aud) => (
                    <button
                      key={aud.id}
                      type="button"
                      onClick={() => setBroadcastTarget(aud.id)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                        broadcastTarget === aud.id
                          ? 'bg-indigo-600 text-white shadow-xs'
                          : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-200'
                      }`}
                    >
                      {aud.label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-slate-700 dark:text-slate-300 mb-1">Notification Title</label>
                <input
                  type="text"
                  placeholder="Broadcast Title"
                  value={broadcastTitle}
                  onChange={(e) => setBroadcastTitle(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-200 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-slate-700 dark:text-slate-300 mb-1">Message Body</label>
                <textarea
                  rows={3}
                  placeholder="System message content..."
                  value={broadcastBody}
                  onChange={(e) => setBroadcastBody(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-200 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <button
                onClick={() => {
                  if (!broadcastTitle || !broadcastBody) return;
                  adminSendBroadcast(broadcastTitle, broadcastBody, broadcastTarget);
                  setBroadcastTitle('');
                  setBroadcastBody('');
                  showToast('Broadcast sent successfully!');
                }}
                className="w-full bg-slate-900 hover:bg-slate-800 text-white font-extrabold py-3 rounded-xl shadow-xs transition-all active:scale-95"
              >
                Dispatch Broadcast
              </button>
            </div>
          </div>
        )}
      </div>

      {/* USER ACTION DRAWER / MODAL */}
      {selectedUser && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-[28px] max-w-md w-full p-5 shadow-2xl border border-slate-100 space-y-4 text-xs font-bold max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-2 border-b border-slate-100">
              <h2 className="text-sm font-extrabold text-slate-900 dark:text-white">Manage User: {selectedUser.name}</h2>
              <button onClick={() => setSelectedUser(null)} className="p-1 text-slate-400">
                <X size={16} />
              </button>
            </div>

            <div className="flex items-center gap-3 p-3 bg-slate-50 dark:bg-slate-800/50 rounded-2xl">
              <img src={selectedUser.avatar} alt="" className="w-12 h-12 rounded-xl object-cover" />
              <div>
                <strong className="block text-slate-900 dark:text-white">{selectedUser.name}</strong>
                <span className="text-[11px] text-slate-500 dark:text-slate-400 font-normal">@{selectedUser.username} • {selectedUser.email}</span>
              </div>
            </div>

            {/* Quick Actions for Selected User */}
            <div className="space-y-2">
              <label className="block text-slate-400 text-[10px] uppercase font-bold">Role & Badges</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => {
                    adminVerifyUser(selectedUser.id, !selectedUser.isVerified, 'Admin toggle verification');
                    setSelectedUser(null);
                    showToast('Verified badge updated');
                  }}
                  className="p-2.5 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 rounded-xl text-left"
                >
                  {selectedUser.isVerified ? 'Revoke Verified' : 'Assign Verified Badge'}
                </button>

                {isSuperAdmin && (
                  <button
                    onClick={() => {
                      adminUpdateUserRole(selectedUser.id, selectedUser.role === 'admin' ? 'creator' : 'admin', 'super_admin');
                      setSelectedUser(null);
                      showToast('User Role Updated');
                    }}
                    className="p-2.5 bg-rose-50 text-rose-800 rounded-xl text-left border border-rose-200"
                  >
                    {selectedUser.role === 'admin' ? 'Revoke Admin' : 'Make Admin'}
                  </button>
                )}
              </div>

              {/* Status Actions */}
              <label className="block text-slate-400 text-[10px] uppercase font-bold pt-2">Account Status Controls</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => {
                    adminSetUserStatus(selectedUser.id, selectedUser.accountStatus === 'suspended' ? 'active' : 'suspended', 'Admin status change');
                    setSelectedUser(null);
                    showToast('Account Status Updated');
                  }}
                  className="p-2.5 bg-amber-50 text-amber-800 border border-amber-200 rounded-xl text-left"
                >
                  {selectedUser.accountStatus === 'suspended' ? 'Unsuspend User' : 'Suspend User'}
                </button>

                <button
                  onClick={() => {
                    adminSetUserStatus(selectedUser.id, selectedUser.accountStatus === 'banned' ? 'active' : 'banned', 'Admin status change');
                    setSelectedUser(null);
                    showToast('Account Ban Updated');
                  }}
                  className="p-2.5 bg-rose-50 text-rose-900 border border-rose-200 rounded-xl text-left"
                >
                  {selectedUser.accountStatus === 'banned' ? 'Unban User' : 'Ban User'}
                </button>
              </div>

              {/* Wallet Adjustments */}
              {isSuperAdmin && (
                <div className="pt-2 space-y-2">
                  <label className="block text-slate-400 text-[10px] uppercase font-bold">Wallet Adjustment (Credit / Debit)</label>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      placeholder="Amount ₹"
                      value={walletAmount}
                      onChange={(e) => setWalletAmount(e.target.value)}
                      className="w-full bg-slate-50 dark:bg-slate-800/50 border border-slate-200 rounded-xl p-2 text-slate-900 dark:text-white"
                    />
                    <button
                      onClick={() => {
                        if (!walletAmount) return;
                        adminAdjustUserWallet(selectedUser.id, Number(walletAmount), 'credit', 'Admin manual credit');
                        setWalletAmount('');
                        setSelectedUser(null);
                        showToast('Wallet credited');
                      }}
                      className="px-3 bg-emerald-600 text-white rounded-xl text-xs"
                    >
                      Credit
                    </button>
                    <button
                      onClick={() => {
                        if (!walletAmount) return;
                        adminAdjustUserWallet(selectedUser.id, Number(walletAmount), 'debit', 'Admin manual debit');
                        setWalletAmount('');
                        setSelectedUser(null);
                        showToast('Wallet debited');
                      }}
                      className="px-3 bg-rose-600 text-white rounded-xl text-xs"
                    >
                      Debit
                    </button>
                  </div>
                </div>
              )}

              {isSuperAdmin && (
                <div className="pt-3 border-t border-slate-100">
                  <button
                    onClick={() => {
                      adminDeleteUser(selectedUser.id, 'Permanent removal');
                      setSelectedUser(null);
                      showToast('User deleted permanently');
                    }}
                    className="w-full py-2.5 bg-rose-600 text-white rounded-xl font-extrabold text-xs"
                  >
                    Delete User Permanently
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* CAMPAIGN CONTROL DRAWER / MODAL */}
      {selectedCampaign && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-[28px] max-w-md w-full p-5 shadow-2xl border border-slate-100 space-y-4 text-xs font-bold">
            <div className="flex items-center justify-between pb-2 border-b border-slate-100">
              <h2 className="text-sm font-extrabold text-slate-900 dark:text-white">Campaign Control: {selectedCampaign.title}</h2>
              <button onClick={() => setSelectedCampaign(null)} className="p-1 text-slate-400">
                <X size={16} />
              </button>
            </div>

            <div className="space-y-1">
              <p className="text-slate-600 dark:text-slate-400">{selectedCampaign.description}</p>
              <span className="text-[11px] text-slate-400 block">
                Brand: {selectedCampaign.brandName} • Budget: ₹{selectedCampaign.totalBudget.toLocaleString('en-IN')}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2 pt-2">
              <button
                onClick={() => {
                  adminSetCampaignStatus(selectedCampaign.id, 'active');
                  setSelectedCampaign(null);
                  showToast('Campaign approved & activated');
                }}
                className="p-2.5 bg-emerald-600 text-white rounded-xl"
              >
                Approve & Activate
              </button>

              <button
                onClick={() => {
                  adminSetCampaignStatus(selectedCampaign.id, 'paused');
                  setSelectedCampaign(null);
                  showToast('Campaign paused');
                }}
                className="p-2.5 bg-amber-600 text-white rounded-xl"
              >
                Pause Campaign
              </button>

              <button
                onClick={() => {
                  adminForceCompleteCampaign(selectedCampaign.id);
                  setSelectedCampaign(null);
                  showToast('Campaign completed');
                }}
                className="p-2.5 bg-blue-600 text-white rounded-xl"
              >
                Force Complete
              </button>

              <button
                onClick={() => {
                  adminReleaseEscrow(selectedCampaign.id, 'full');
                  setSelectedCampaign(null);
                  showToast('Escrow released');
                }}
                className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                Release Escrow
              </button>
            </div>

            {isSuperAdmin && (
              <button
                onClick={() => {
                  adminDeleteCampaign(selectedCampaign.id);
                  setSelectedCampaign(null);
                  showToast('Campaign deleted');
                }}
                className="w-full py-2.5 bg-rose-600 text-white rounded-xl"
              >
                Delete Campaign Brief
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

