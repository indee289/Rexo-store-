import { GlobalToaster } from './components/common/GlobalToaster';
import { ToastProvider } from './context/ToastContext';
import React, { useState, useEffect, Suspense } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { StoreProvider, useStore } from './context/StoreContext';
import { BottomNavigation } from './components/common/BottomNavigation';
import { RoleSwitcher } from './components/common/RoleSwitcher';
const HomeView = React.lazy(() => import('./components/home/HomeView').then(m => ({ default: m.HomeView })));
const CampaignsView = React.lazy(() => import('./components/campaigns/CampaignsView').then(m => ({ default: m.CampaignsView })));
const WalletView = React.lazy(() => import('./components/wallet/WalletView').then(m => ({ default: m.WalletView })));
const NotificationsView = React.lazy(() => import('./components/notifications/NotificationsView').then(m => ({ default: m.NotificationsView })));
const ProfileView = React.lazy(() => import('./components/profile/ProfileView').then(m => ({ default: m.ProfileView })));
const SettingsView = React.lazy(() => import('./components/settings/SettingsView').then(m => ({ default: m.SettingsView })));
const AdminCenterView = React.lazy(() => import('./components/admin/AdminCenterView').then(m => ({ default: m.AdminCenterView })));
const ShopHomeView = React.lazy(() => import('./components/shop/ShopHomeView').then(m => ({ default: m.ShopHomeView })));
import { deepLinkService } from './services/deepLinkService';
const AuthView = React.lazy(() => import('./components/auth/AuthView').then(m => ({ default: m.AuthView })));
import { supabase } from './lib/supabaseClient';
import { supabaseAuthService } from './services/supabaseAuthService';


const ScreenSkeleton = () => (
  <div className="bg-slate-100 min-h-screen text-slate-900 flex justify-center antialiased">
    <main className="w-full max-w-lg bg-[#F8FAFC] dark:bg-slate-950 min-h-screen relative flex flex-col p-4 space-y-6">
      <div className="flex items-center justify-between pt-2">
         <div className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-800 animate-pulse"></div>
         <div className="w-8 h-8 rounded-full bg-slate-200 dark:bg-slate-800 animate-pulse"></div>
      </div>
      <div className="space-y-3">
        <div className="w-48 h-8 bg-slate-200 dark:bg-slate-800 rounded-lg animate-pulse"></div>
        <div className="w-32 h-4 bg-slate-200 dark:bg-slate-800 rounded-lg animate-pulse"></div>
      </div>
      <div className="w-full h-40 bg-slate-200 dark:bg-slate-800 rounded-3xl animate-pulse"></div>
      <div className="flex gap-3">
         <div className="w-24 h-8 rounded-full bg-slate-200 dark:bg-slate-800 animate-pulse"></div>
         <div className="w-24 h-8 rounded-full bg-slate-200 dark:bg-slate-800 animate-pulse"></div>
         <div className="w-24 h-8 rounded-full bg-slate-200 dark:bg-slate-800 animate-pulse"></div>
      </div>
      <div className="space-y-4 pt-4">
         <div className="w-full h-24 bg-slate-200 dark:bg-slate-800 rounded-3xl animate-pulse"></div>
         <div className="w-full h-24 bg-slate-200 dark:bg-slate-800 rounded-3xl animate-pulse"></div>
      </div>
    </main>
  </div>
);

const MainAppContent: React.FC = () => {
  const { currentUser, setRealSessionUser, unreadNotificationsCount } = useStore();
  const [activeTab, setActiveTab] = useState<string>('home');
  const [isRoleSwitcherOpen, setIsRoleSwitcherOpen] = useState(false);
  const [authLoading, setAuthLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session?.user) {
          const { data: mfaData } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
          if (mfaData?.nextLevel === 'aal2' && mfaData.nextLevel !== mfaData.currentLevel) {
            setRealSessionUser(null);
          } else {
            const profile = await supabaseAuthService.getUserProfile(session.user.id);
            if (profile) setRealSessionUser(profile);
          }
        }
      } catch (e) {
        console.warn('Supabase Auth error:', e);
      } finally {
        setAuthLoading(false);
      }
    };

    checkAuth();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (session?.user) {
        const { data: mfaData } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
        if (mfaData?.nextLevel === 'aal2' && mfaData.nextLevel !== mfaData.currentLevel) {
          setRealSessionUser(null);
        } else {
          const profile = await supabaseAuthService.getUserProfile(session.user.id);
          if (profile) setRealSessionUser(profile);
        }
      } else {
        setRealSessionUser(null);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    deepLinkService.registerHandler({
      navigateToCampaign: () => setActiveTab('campaigns'),
      navigateToWallet: () => setActiveTab('wallet'),
      navigateToWithdrawalDetails: () => setActiveTab('wallet'),
      navigateToAdminMessage: () => setActiveTab('notifications'),
      navigateToKycStatus: () => setActiveTab('profile'),
      navigateToProfile: () => setActiveTab('profile'),
    });
    return () => deepLinkService.unregisterHandler();
  }, []);

  const handleNavigateScreen = (screenName: string) => {
    switch (screenName) {
      case 'CampaignDetails': return setActiveTab('campaigns');
      case 'Wallet':
      case 'WithdrawalDetails': return setActiveTab('wallet');
      case 'KYCStatus':
      case 'Profile': return setActiveTab('profile');
      case 'AdminMessage':
      default: return setActiveTab('notifications');
    }
  };

  if (authLoading) return <ScreenSkeleton />;

  if (!currentUser) {
    return <Suspense fallback={<ScreenSkeleton />}><AuthView onSuccess={() => setActiveTab('home')} /></Suspense>;
  }

  const renderCurrentView = () => {
    switch (activeTab) {
      case 'home':
        return (
          <HomeView
            onNavigateTab={setActiveTab}
            onOpenPostCampaignModal={() => setActiveTab('campaigns')}
            onSelectCampaignToApply={() => setActiveTab('campaigns')}
            onNavigateNotifications={() => setActiveTab('notifications')}
          />
        );
      case 'campaigns': return <CampaignsView onNavigateNotifications={() => setActiveTab('notifications')} />;
      case 'wallet': return <WalletView onNavigateNotifications={() => setActiveTab('notifications')} />;
      case 'shop': return <ShopHomeView onNavigateNotifications={() => setActiveTab('notifications')} />;
      case 'notifications': return <NotificationsView onNavigateToScreen={handleNavigateScreen} />;
      case 'profile':
        return (
          <ProfileView
            onNavigateTab={setActiveTab}
            onNavigateToSettings={() => setActiveTab('settings')}
            onNavigateToAdminCenter={() => setActiveTab('admin')}
            onOpenRoleSwitcher={() => setIsRoleSwitcherOpen(true)}
            onNavigateNotifications={() => setActiveTab('notifications')}
          />
        );
      case 'settings': return <SettingsView onBack={() => setActiveTab('profile')} />;
      case 'admin': 
        if (currentUser.role !== 'admin' && currentUser.role !== 'brand') {
          return <div className="p-8 text-center text-rose-500 font-bold">Unauthorized Access</div>;
        }
        return <AdminCenterView onBackToProfile={() => setActiveTab('profile')} />;
      default:
        return (
          <HomeView
            onNavigateTab={setActiveTab}
            onOpenPostCampaignModal={() => setActiveTab('campaigns')}
            onSelectCampaignToApply={() => setActiveTab('campaigns')}
          />
        );
    }
  };

  const isFullScreenRoute = activeTab === 'settings' || activeTab === 'admin';

  return (
    <div className="bg-slate-100 min-h-screen text-slate-900 flex justify-center antialiased">
      <main id="app-container" className="w-full max-w-lg bg-[#F8FAFC] min-h-screen relative flex flex-col shadow-xl overflow-x-hidden">
        <section id="app-viewport" className="flex-1 relative">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -4 }}
              transition={{ duration: 0.15, ease: "easeOut" }}
              className="h-full w-full"
            >
              <Suspense fallback={<ScreenSkeleton />}>
              {renderCurrentView()}
            </Suspense>
            </motion.div>
          </AnimatePresence>
        </section>
        {!isFullScreenRoute && (
          <BottomNavigation activeTab={activeTab} onTabChange={setActiveTab} unreadNotificationsCount={unreadNotificationsCount} />
        )}
        <RoleSwitcher isOpen={isRoleSwitcherOpen} onClose={() => setIsRoleSwitcherOpen(false)} />
      </main>
    </div>
  );
};

export default function App() {
  return (
    <ToastProvider>
      <StoreProvider>
      <GlobalToaster />
      <MainAppContent />
    </StoreProvider>
      </ToastProvider>
  );
}
