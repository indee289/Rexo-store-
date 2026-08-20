import React, { useState, useEffect } from 'react';
import { useStore } from '../../context/StoreContext';
import { storageService } from '../../services/storageService';
import { Camera } from 'lucide-react';
import { getTranslation } from '../../utils/i18n';
import {
  Edit3,
  Globe,
  Languages,
  Moon,
  Sun,
  Bell,
  HelpCircle,
  BookOpen,
  Headphones,
  ChevronRight,
  ArrowUpRight,
  UserPlus,
  Share2,
  X,
  Instagram,
  Youtube,
  ShieldCheck,
  LogOut,
  CheckCircle2,
  Lock,
  Copy,
  Check,
  ToggleLeft,
  ToggleRight,
  Send,
  PackageCheck,
  Crown,
  UserCheck,
  FileText,
} from 'lucide-react';
import { SubscriptionModal } from './index';
import { PrivacyPolicyModal } from '../common/PrivacyPolicyModal';
import { PageHeader } from '../ui';

interface ProfileViewProps {
  onNavigateTab: (tab: string) => void;
  onNavigateToSettings: () => void;
  onNavigateToAdminCenter?: () => void;
  onOpenRoleSwitcher: () => void;
  onNavigateNotifications?: () => void;
}

export const ProfileView: React.FC<ProfileViewProps> = ({
  onNavigateTab,
  onNavigateToSettings,
  onNavigateToAdminCenter,
  onOpenRoleSwitcher,
  onNavigateNotifications,
}) => {
  const {
    state,
    currentUser,
    currentWallet,
    userSettings,
    updateUserProfile,
    updateUserSettings,
    resetApp,
    unreadNotificationsCount,
    requestNativePermission,
  } = useStore();

  const isAdmin = currentUser.role === 'admin';

  // Get real translated strings based on user's active language choice
  const t = getTranslation(userSettings.language);

  // Modal / Drawer state
  const [activeModal, setActiveModal] = useState<string | null>(null);

  // Toast feedback
  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const [copiedLink, setCopiedLink] = useState(false);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3000);
  };

  // Form states for Edit Profile
  const [editName, setEditName] = useState(currentUser.name || '');
  const [editUsername, setEditUsername] = useState(currentUser.username || '');
  const [editBio, setEditBio] = useState(currentUser.bio || '');
  const [editAge, setEditAge] = useState(currentUser.age?.toString() || '');
  const [editWebsite, setEditWebsite] = useState(currentUser.website || '');
  
  // File upload for profile picture
  const fileInputRef = React.useRef<HTMLInputElement>(null);
  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    
    showToast('Uploading avatar to server...');
    const filePath = `${currentUser.id}/${Date.now()}_avatar.jpg`;
    const { publicUrl, error } = await storageService.uploadFile('avatars', filePath, file);
    
    if (error || !publicUrl) {
       showToast('Failed to upload photo.');
       return;
    }
    
    updateUserProfile({ avatar: publicUrl });
    showToast('Avatar updated securely!');
  };


  // Form states for Connected Accounts
  const [editInsta, setEditInsta] = useState(currentUser.socialLinks?.instagram || '');
  const [editYt, setEditYt] = useState(currentUser.socialLinks?.youtube || '');
  const [editX, setEditX] = useState(currentUser.socialLinks?.x || '');

  // Form states for Support Ticket
  const [supportSubject, setSupportSubject] = useState('');
  const [supportMessage, setSupportMessage] = useState('');

  // REAL COMPUTED NUMBERS (NO fake hardcoded dummy values)
  const myApplications = state.applications.filter((a) => a.creatorId === currentUser.id);
  const totalEarned = currentWallet.totalEarned || myApplications
    .filter((a) => a.status === 'approved' || a.status === 'paid')
    .reduce((sum, a) => sum + (a.feeRequested || 0), 0);

  const totalVideos = myApplications.filter((a) => a.deliverableUrl).length;

  const totalViewsFormatted = currentUser.followersCount
    ? currentUser.followersCount >= 1000000
      ? `${(currentUser.followersCount / 1000000).toFixed(1)}M`
      : `${(currentUser.followersCount / 1000).toFixed(0)}K`
    : '0';

  const memberSinceFormatted = currentUser.createdAt
    ? new Date(currentUser.createdAt).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      })
    : 'Today';

  // Social account count
  const connectedCount = [
    currentUser.socialLinks?.instagram,
    currentUser.socialLinks?.youtube,
    currentUser.socialLinks?.x,
  ].filter(Boolean).length;

  // Real Theme switcher logic
  const handleSetTheme = (themeMode: 'light' | 'dark' | 'system') => {
    localStorage.setItem('rexo_theme', themeMode);
    if (themeMode === 'dark') {
      document.documentElement.classList.add('dark');
    } else if (themeMode === 'light') {
      document.documentElement.classList.remove('dark');
    } else {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      if (prefersDark) document.documentElement.classList.add('dark');
      else document.documentElement.classList.remove('dark');
    }
    updateUserSettings({ currency: themeMode });
    showToast(`Theme changed to ${themeMode.toUpperCase()}`);
    setActiveModal(null);
  };

  // Real Language switcher logic
  const handleSetLanguage = (langName: string) => {
    updateUserSettings({ language: langName });
    showToast(`Language updated to ${langName}`);
    setActiveModal(null);
  };

  // Real Profile update handler
  const handleEditProfileSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateUserProfile({
      name: editName,
      username: editUsername.replace(/^@/, ''),
      bio: editBio,
      age: editAge ? parseInt(editAge, 10) : undefined,
      website: editWebsite,
    });
    showToast('Profile updated!');
    setActiveModal(null);
  };

  // Real Connected Accounts save handler
  const handleSocialSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateUserProfile({
      socialLinks: {
        instagram: editInsta,
        youtube: editYt,
        x: editX,
      },
    });
    showToast('Connected accounts saved!');
    setActiveModal(null);
  };

  // Support ticket handler
  const handleSupportSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    showToast(t.supportSubmitted);
    setSupportSubject('');
    setSupportMessage('');
    setActiveModal(null);
  };

  // Copy referral link handler
  
  // Mock Data for Profile Chart
  const profileChartData = [
    { name: 'Completed Campaigns', value: 12, color: '#10b981' },
    { name: 'Active Campaigns', value: 3, color: '#6366f1' },
    { name: 'Pending Reviews', value: 2, color: '#f59e0b' },
  ];

  const handleCopyReferral = () => {
    const refLink = `https://rexomarket.app/ref/${currentUser.username}`;
    navigator.clipboard.writeText(refLink);
    setCopiedLink(true);
    showToast(t.copied);
    setTimeout(() => setCopiedLink(false), 2500);
  };

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans transition-colors">
      <div className="max-w-2xl mx-auto px-4 space-y-5">
        {/* HEADER: TITLE & NOTIFICATION BELL */}
        <PageHeader 
          title={t.profileTitle}
          actions={
            <button
              onClick={onNavigateNotifications}
              className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 relative shadow-2xs hover:bg-slate-50 transition-all active:scale-95"
              title="Notifications"
            >
              <Bell size={20} />
              {unreadNotificationsCount > 0 && (
                <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-rose-500 rounded-full ring-2 ring-white dark:ring-slate-900" />
              )}
            </button>
          }
        />

        {/* FEEDBACK TOAST */}
        {toastMsg && (
          <div className="p-3.5 bg-emerald-50 dark:bg-emerald-950/80 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200 text-xs font-bold rounded-2xl flex items-center justify-between shadow-2xs">
            <span>{toastMsg}</span>
            <button onClick={() => setToastMsg(null)}>
              <X size={14} />
            </button>
          </div>
        )}

        {/* 1. MAIN PROFILE CARD */}
        <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 p-5 pt-8 shadow-2xs relative text-center mt-8">
          {/* Overlapping Top Avatar */}
          <div className="relative inline-block -mt-16 mb-2">
            <img
              src={currentUser.avatar}
              alt={currentUser.name}
              className="w-20 h-20 rounded-full object-cover border-4 border-[#F4F6F8] dark:border-slate-950 shadow-md bg-slate-900"
            />
            {currentUser.isVerified && (
              <span className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95">
                <CheckCircle2 size={12} />
              </span>
            )}
          </div>

          {/* Edit Profile Pencil Icon */}
          <button
            onClick={() => setActiveModal('edit_profile')}
            className="absolute top-4 right-4 p-2 rounded-full text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-all active:scale-95"
            title="Edit Profile"
          >
            <Edit3 size={18} />
          </button>

          {/* User Handle & Join Date */}
          <h2 className="text-lg font-bold text-slate-900 dark:text-white tracking-tight">
            @{currentUser.username || currentUser.email.split('@')[0] || 'username'}
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-0.5">
            {t.memberSince}: {memberSinceFormatted}
          </p>

          {/* Horizontal Divider */}
          <div className="border-t border-slate-100 dark:border-slate-800/80 my-4" />

          {/* 3 Columns Real Computed Stats */}
          <div className="grid grid-cols-3 gap-2 text-center">
            <div>
              <div className="text-base font-extrabold text-slate-900 dark:text-white">
                ₹{totalEarned.toLocaleString('en-IN')}
              </div>
              <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium block">
                {t.moneyEarned}
              </span>
            </div>

            <div>
              <div className="text-base font-extrabold text-slate-900 dark:text-white">
                {totalVideos}
              </div>
              <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium block">
                {t.totalVideos}
              </span>
            </div>

            <div>
              <div className="text-base font-extrabold text-slate-900 dark:text-white">
                {totalViewsFormatted}
              </div>
              <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium block">
                {t.totalViews}
              </span>
            </div>
          </div>
        </div>

        {/* 2. ACCOUNT & COMMERCE GROUP */}
        <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800/80 shadow-2xs text-xs font-bold text-slate-900 dark:text-white">
          {/* Connected Accounts */}
          <button
            onClick={() => setActiveModal('connected_accounts')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <Share2 size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.connectedAccounts}</span>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <span className="text-xs text-slate-500 dark:text-slate-400 font-semibold">
                {connectedCount > 0 ? `${connectedCount} ${t.linkedCount}` : 'Connect'}
              </span>
              <ChevronRight size={16} className="text-slate-400" />
            </div>
          </button>

          {/* Referrals */}
          <button
            onClick={() => setActiveModal('referrals')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <UserPlus size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.referrals}</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-500 dark:text-slate-400">
              <span>{t.earnPercent}</span>
              <ChevronRight size={16} />
            </div>
          </button>

          {/* Subscription */}
          <button
            onClick={() => setActiveModal('subscription')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <Crown size={18} className="text-slate-700 dark:text-slate-300" />
              <span>Subscription</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-500 dark:text-slate-400">
              <span>Upgrade Plan</span>
              <ChevronRight size={16} />
            </div>
          </button>

          {/* My Purchases & Downloads */}
          <button
            onClick={() => onNavigateTab('shop')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <PackageCheck size={18} className="text-slate-700 dark:text-slate-300" />
              <span>My Purchases & Downloads</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-500 dark:text-slate-400">
              <span>View Unlocked</span>
              <ChevronRight size={16} />
            </div>
          </button>
        </div>

        {/* 3. WORKSPACE & PREFERENCES GROUP */}
        <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800/80 shadow-2xs text-xs font-bold text-slate-900 dark:text-white">
          {/* Switch Workspace / Role */}
          <button
            onClick={onOpenRoleSwitcher}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <UserCheck size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.switchWorkspace}</span>
            </div>
            <ChevronRight size={16} className="text-slate-400" />
          </button>

          {/* Security & Settings */}
          <button
            onClick={onNavigateToSettings}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <Lock size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.security}</span>
            </div>
            <ChevronRight size={16} className="text-slate-400" />
          </button>

          {/* Language Selector Item */}
          <button
            onClick={() => setActiveModal('language')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <Languages size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.language}</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 dark:text-slate-400">
              <span>{userSettings.language || 'English'}</span>
              <ChevronRight size={16} />
            </div>
          </button>

          {/* Theme Switcher Item */}
          <button
            onClick={() => setActiveModal('theme')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <Moon size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.theme}</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 dark:text-slate-400">
              <span className="capitalize">
                {userSettings.currency === 'dark' ? 'Dark' : userSettings.currency === 'light' ? 'Light' : 'System'}
              </span>
              <ChevronRight size={16} />
            </div>
          </button>

          {/* Notifications Item */}
          <button
            onClick={() => setActiveModal('notification_settings')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <Bell size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.notifications}</span>
            </div>
            <ChevronRight size={16} className="text-slate-400" />
          </button>
        </div>

        {/* 4. SUPPORT & RESOURCES GROUP */}
        <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800/80 shadow-2xs text-xs font-bold text-slate-900 dark:text-white">
          <button
            onClick={() => setActiveModal('faq')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <HelpCircle size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.faq}</span>
            </div>
            <ChevronRight size={16} className="text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('resources')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <BookOpen size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.resources}</span>
            </div>
            <ChevronRight size={16} className="text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('support')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <Headphones size={18} className="text-slate-700 dark:text-slate-300" />
              <span>{t.support}</span>
            </div>
            <ArrowUpRight size={18} className="text-slate-400" />
          </button>

          <button
            onClick={() => setActiveModal('privacy_policy')}
            className="w-full p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <FileText size={18} className="text-indigo-600 dark:text-indigo-400" />
              <span>{t.privacyPolicy}</span>
            </div>
            <ChevronRight size={16} className="text-slate-400" />
          </button>
        </div>

        {/* 5. PROTECTED ADMIN CONSOLE & LOGOUT */}
        <div className="pt-1 space-y-2">
          {isAdmin && onNavigateToAdminCenter && (
            <button
              onClick={onNavigateToAdminCenter}
              className="w-full p-3.5 rounded-2xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900 text-rose-700 dark:text-rose-300 font-extrabold text-xs flex items-center justify-between shadow-2xs"
            >
              <div className="flex items-center gap-2 shrink-0">
                <ShieldCheck size={16} />
                <span>Protected Admin Console</span>
              </div>
              <ChevronRight size={16} />
            </button>
          )}

          <button
            onClick={() => {
              resetApp();
              showToast('Logged out');
            }}
            className="w-full py-3.5 px-4 rounded-2xl bg-rose-50 dark:bg-rose-950/30 text-rose-600 dark:text-rose-400 font-extrabold text-xs flex items-center justify-center gap-2 border border-rose-200/80 dark:border-rose-900/50 hover:bg-rose-100 transition-all"
          >
            <LogOut size={15} /> {t.logout}
          </button>
        </div>
      </div>

      {/* LANGUAGE SELECTOR MODAL */}
      {activeModal === 'language' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white flex items-center gap-2">
                <Languages size={18} /> Select Language / भाषा चुनें
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <div className="space-y-2">
              {[
                { name: 'English', label: 'English (US)', flag: '🇺🇸' },
                { name: 'Hindi (हिंदी)', label: 'Hindi (हिंदी)', flag: '🇮🇳' },
                { name: 'Hinglish', label: 'Hinglish', flag: '🇮🇳' },
                { name: 'Spanish (Español)', label: 'Spanish (Español)', flag: '🇪🇸' },
              ].map((lang) => (
                <button
                  key={lang.name}
                  onClick={() => handleSetLanguage(lang.name)}
                  className={`w-full p-3.5 rounded-2xl border text-left font-bold flex items-center justify-between transition-all ${
                    userSettings.language === lang.name
                      ? 'bg-indigo-50 dark:bg-indigo-950/60 border-indigo-500 text-indigo-700 dark:text-indigo-300'
                      : 'bg-slate-50 dark:bg-slate-800/60 border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white hover:bg-slate-100'
                  }`}
                >
                  <span className="flex items-center gap-2">
                    <span>{lang.flag}</span>
                    <span>{lang.label}</span>
                  </span>
                  {userSettings.language === lang.name && <Check size={16} />}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* THEME SWITCHER MODAL */}
      {activeModal === 'theme' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white flex items-center gap-2">
                <Moon size={18} /> Select Theme / थीम बदलें
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <div className="space-y-2">
              {[
                { id: 'light', label: 'Light Mode', icon: Sun },
                { id: 'dark', label: 'Dark Mode', icon: Moon },
                { id: 'system', label: 'System Default', icon: Globe },
              ].map((themeOpt) => {
                const Icon = themeOpt.icon;
                const isSelected = userSettings.currency === themeOpt.id;
                return (
                  <button
                    key={themeOpt.id}
                    onClick={() => handleSetTheme(themeOpt.id as any)}
                    className={`w-full p-3.5 rounded-2xl border text-left font-bold flex items-center justify-between transition-all ${
                      isSelected
                        ? 'bg-indigo-50 dark:bg-indigo-950/60 border-indigo-500 text-indigo-700 dark:text-indigo-300'
                        : 'bg-slate-50 dark:bg-slate-800/60 border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white hover:bg-slate-100'
                    }`}
                  >
                    <span className="flex items-center gap-2">
                      <Icon size={16} />
                      <span>{themeOpt.label}</span>
                    </span>
                    {isSelected && <Check size={16} />}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* NOTIFICATIONS SETTINGS MODAL */}
      {activeModal === 'notification_settings' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white flex items-center gap-2">
                <Bell size={18} /> Notification Settings
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <div className="space-y-3">
              <div className="p-3.5 bg-slate-50 dark:bg-slate-800 rounded-2xl flex items-center justify-between">
                <div>
                  <strong className="block text-slate-900 dark:text-white font-bold">Push Notifications</strong>
                  <span className="text-[10px] text-slate-400">Alerts for payouts and campaign status</span>
                </div>
                <button
                  onClick={() => {
                    updateUserSettings({ pushNotifications: !userSettings.pushNotifications });
                    showToast('Push settings updated');
                  }}
                  className="text-indigo-600"
                >
                  {userSettings.pushNotifications ? <ToggleRight size={28} /> : <ToggleLeft size={28} className="text-slate-300" />}
                </button>
              </div>

              <div className="p-3.5 bg-slate-50 dark:bg-slate-800 rounded-2xl flex items-center justify-between">
                <div>
                  <strong className="block text-slate-900 dark:text-white font-bold">Email Digest</strong>
                  <span className="text-[10px] text-slate-400">Weekly briefs & opportunity updates</span>
                </div>
                <button
                  onClick={() => {
                    updateUserSettings({ emailNotifications: !userSettings.emailNotifications });
                    showToast('Email preference updated');
                  }}
                  className="text-indigo-600"
                >
                  {userSettings.emailNotifications ? <ToggleRight size={28} /> : <ToggleLeft size={28} className="text-slate-300" />}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* CONNECTED ACCOUNTS MODAL */}
      {activeModal === 'connected_accounts' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                Connected Social Accounts
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSocialSubmit} className="space-y-3">
              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1 flex items-center gap-1.5">
                  <Instagram size={14} className="text-pink-600" /> Instagram Handle
                </label>
                <input
                  type="text"
                  placeholder="@username"
                  value={editInsta}
                  onChange={(e) => setEditInsta(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1 flex items-center gap-1.5">
                  <Youtube size={14} className="text-red-600" /> YouTube Channel
                </label>
                <input
                  type="text"
                  placeholder="https://youtube.com/@channel"
                  value={editYt}
                  onChange={(e) => setEditYt(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1 flex items-center gap-1.5">
                  <Globe size={14} className="text-blue-600" /> X (Twitter) Handle
                </label>
                <input
                  type="text"
                  placeholder="@username"
                  value={editX}
                  onChange={(e) => setEditX(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <button
                type="submit"
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                Save Connected Handles
              </button>
            </form>
          </div>
        </div>
      )}

      {/* REFERRALS MODAL */}
      {activeModal === 'referrals' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs text-center">
            <div className="flex items-center justify-between text-left">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                Referral Program
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <div className="p-4 bg-indigo-50 dark:bg-indigo-950/60 rounded-2xl text-indigo-900 dark:text-indigo-200 space-y-1">
              <span className="text-lg font-bold block">Earn 10% Lifetime</span>
              <p className="text-[11px]">
                Invite fellow creators & brands. Get 10% bonus on every campaign payout!
              </p>
            </div>

            <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white font-mono text-xs flex items-center justify-between">
              <span className="truncate">https://rexomarket.app/ref/{currentUser.username}</span>
              <button
                onClick={handleCopyReferral}
                className="p-1.5 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 rounded-lg transition-all shrink-0"
              >
                {copiedLink ? <Check size={16} /> : <Copy size={16} />}
              </button>
            </div>

            <button
              onClick={handleCopyReferral}
              className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
            >
              {t.shareReferral}
            </button>
          </div>
        </div>
      )}

      {/* EDIT PROFILE MODAL */}
      {activeModal === 'edit_profile' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                Edit Profile Info
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            
            <form onSubmit={handleEditProfileSubmit} className="space-y-3">
              {/* Avatar Upload Area */}
              <div className="flex flex-col items-center justify-center py-2">
                <div className="relative group">
                  <img
                    src={currentUser.avatar}
                    alt="Current Avatar"
                    className="w-20 h-20 rounded-full object-cover border-4 border-slate-100 dark:border-slate-800"
                  />
                  <input 
                    type="file" 
                    ref={fileInputRef} 
                    onChange={handleAvatarUpload} 
                    accept="image/*" 
                    className="hidden" 
                  />
                  <div 
                    onClick={async (e) => {
                      e.preventDefault();
                      if (requestNativePermission) {
                        const allowed = await requestNativePermission('gallery');
                        if (allowed) fileInputRef.current?.click();
                      } else {
                        fileInputRef.current?.click();
                      }
                    }}
                    className="absolute inset-0 bg-black/50 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                  >
                    <Camera size={20} className="text-white" />
                  </div>
                </div>
                <button 
                  type="button" 
                  onClick={() => fileInputRef.current?.click()}
                  className="mt-2 text-[11px] font-bold text-indigo-600 dark:text-indigo-400 hover:underline"
                >
                  Change Photo
                </button>
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Full Name
                </label>
                <input
                  type="text"
                  required
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Username (@handle)
                </label>
                <input
                  type="text"
                  required
                  value={editUsername}
                  onChange={(e) => setEditUsername(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Bio
                </label>
                <textarea
                  rows={2}
                  value={editBio}
                  onChange={(e) => setEditBio(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl p-3 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>
              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Age
                </label>
                <input
                  type="number"
                  value={editAge}
                  onChange={(e) => setEditAge(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                  placeholder="e.g. 24"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Website / Portfolio
                </label>
                <input
                  type="url"
                  value={editWebsite}
                  onChange={(e) => setEditWebsite(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                  placeholder="https://your-portfolio.com"
                />
              </div>


              <button
                type="submit"
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                {t.save}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* FAQ MODAL */}
      {activeModal === 'faq' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white flex items-center gap-1.5">
                <HelpCircle size={18} /> FAQ
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <div className="space-y-2 text-slate-600 dark:text-slate-300 leading-relaxed max-h-80 overflow-y-auto">
              <div className="p-3.5 bg-slate-50 dark:bg-slate-800/60 rounded-2xl">
                <h4 className="font-bold text-slate-900 dark:text-white">How do payouts work?</h4>
                <p className="text-[11px] mt-1">
                  Payouts are released directly from escrow into your linked UPI/Bank account once brand approves your deliverable.
                </p>
              </div>

              <div className="p-3.5 bg-slate-50 dark:bg-slate-800/60 rounded-2xl">
                <h4 className="font-bold text-slate-900 dark:text-white">Are there platform fees?</h4>
                <p className="text-[11px] mt-1">
                  Creators receive 100% of the agreed payout amount with zero deductions.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* SUPPORT MODAL */}
      {activeModal === 'support' && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-sm w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Headphones size={18} /> Customer Support
              </h3>
              <button
                onClick={() => setActiveModal(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSupportSubmit} className="space-y-3">
              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Subject
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Issue with payout or brief"
                  value={supportSubject}
                  onChange={(e) => setSupportSubject(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Message
                </label>
                <textarea
                  required
                  rows={3}
                  placeholder="Describe your question or issue in detail..."
                  value={supportMessage}
                  onChange={(e) => setSupportMessage(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl p-3 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <button
                type="submit"
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                <Send size={14} /> Send Message
              </button>
            </form>
          </div>
        </div>
      )}

      {/* SUBSCRIPTION MODAL */}
      {activeModal === 'subscription' && (
        <SubscriptionModal
          onClose={() => setActiveModal(null)}
          onShowToast={showToast}
        />
      )}

      {/* PRIVACY POLICY MODAL */}
      <PrivacyPolicyModal
        isOpen={activeModal === 'privacy_policy'}
        onClose={() => setActiveModal(null)}
      />
    </div>
  );
};
