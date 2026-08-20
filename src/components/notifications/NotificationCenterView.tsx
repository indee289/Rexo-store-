import React, { useState } from 'react';
import {
  Bell,
  CheckCheck,
  Trash2,
  Filter,
  RefreshCw,
  Megaphone,
  Briefcase,
  Wallet as WalletIcon,
  ShieldCheck,
  AlertTriangle,
  ArrowRight,
  Sparkles,
  Inbox,
  CheckCircle2,
  XCircle,
  Clock,
} from 'lucide-react';
import { useStore } from '../../context/StoreContext';
import { AppNotification, NotificationType } from '../../types';
import { deepLinkService } from '../../services/deepLinkService';

interface NotificationCenterViewProps {
  onBackToApp?: () => void;
  onNavigateToScreen?: (screen: string, targetId?: string) => void;
}

export const NotificationCenterView: React.FC<NotificationCenterViewProps> = ({
  onBackToApp,
  onNavigateToScreen,
}) => {
  const {
    state,
    currentUser,
    unreadNotificationsCount,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    deleteNotification,
    refreshNotifications,
  } = useStore();

  const [activeTab, setActiveTab] = useState<'all' | 'unread' | 'campaign' | 'financial' | 'account' | 'admin'>('all');
  const [isRefreshing, setIsRefreshing] = useState(false);

  // User Notifications
  const userNotifications = state.notifications.filter(
    (n) => n.userId === currentUser.id || n.userId === 'all'
  );

  // Filtered Notifications
  const filteredNotifications = userNotifications.filter((n) => {
    if (activeTab === 'unread') return !n.isRead;
    if (activeTab === 'campaign') return n.type.includes('campaign') || n.type.includes('creator');
    if (activeTab === 'financial') return n.type.includes('withdrawal') || n.type.includes('wallet') || n.type.includes('deposit');
    if (activeTab === 'account') return n.type.includes('kyc') || n.type.includes('verified') || n.type.includes('security');
    if (activeTab === 'admin') return n.type === 'admin_broadcast';
    return true;
  });

  const handlePullToRefresh = () => {
    setIsRefreshing(true);
    refreshNotifications();
    setTimeout(() => {
      setIsRefreshing(false);
    }, 600);
  };

  const handleNotificationTap = (notif: AppNotification) => {
    if (!notif.isRead) {
      markNotificationAsRead(notif.id);
    }

    if (onNavigateToScreen) {
      const { screen, targetId } = notif.payload || {};
      if (screen) {
        onNavigateToScreen(screen, targetId);
      } else {
        // Fallback
        if (notif.type.includes('campaign')) onNavigateToScreen('CampaignDetails', targetId);
        else if (notif.type.includes('withdrawal') || notif.type.includes('wallet')) onNavigateToScreen('Wallet');
        else if (notif.type.includes('kyc')) onNavigateToScreen('KYCStatus');
        else onNavigateToScreen('AdminMessage', notif.id);
      }
    } else {
      deepLinkService.handleNotificationClick(notif);
    }
  };

  const getTypeIcon = (type: NotificationType) => {
    switch (type) {
      case 'campaign_approved':
      case 'campaign_application_accepted':
      case 'creator_selected':
        return <CheckCircle2 className="w-5 h-5 text-emerald-500" />;

      case 'campaign_rejected':
      case 'campaign_application_rejected':
      case 'creator_removed':
        return <XCircle className="w-5 h-5 text-rose-500" />;

      case 'withdrawal_approved':
      case 'deposit_approved':
      case 'wallet_credited':
        return <WalletIcon className="w-5 h-5 text-emerald-600" />;

      case 'withdrawal_rejected':
      case 'deposit_rejected':
      case 'wallet_debited':
        return <WalletIcon className="w-5 h-5 text-amber-600" />;

      case 'kyc_approved':
      case 'user_verified':
        return <ShieldCheck className="w-5 h-5 text-indigo-600" />;

      case 'kyc_rejected':
      case 'security_alert':
        return <AlertTriangle className="w-5 h-5 text-red-500" />;

      case 'admin_broadcast':
        return <Megaphone className="w-5 h-5 text-purple-600" />;

      default:
        return <Briefcase className="w-5 h-5 text-blue-500" />;
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 pb-28 pt-4 font-sans">
      <div className="max-w-2xl mx-auto px-4 space-y-5">
        {/* DISCOVER-STYLE HEADER FOR ALERTS */}
        <div className="flex items-center justify-between pt-1">
          <div>
            <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
              Alerts
            </h1>
            <p className="text-xs text-slate-500">
              {unreadNotificationsCount > 0
                ? `${unreadNotificationsCount} unread update${unreadNotificationsCount > 1 ? 's' : ''}`
                : 'All notification updates up to date'}
            </p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handlePullToRefresh}
              className={`p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 relative shadow-2xs hover:bg-slate-50 transition-all active:scale-95 ${
                isRefreshing ? 'animate-spin' : ''
              }`}
              title="Refresh Alerts"
            >
              <RefreshCw size={18} />
            </button>

            <div className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-indigo-600 dark:text-indigo-400 relative shadow-2xs">
              <Bell size={20} />
              {unreadNotificationsCount > 0 && (
                <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-rose-500 rounded-full ring-2 ring-white dark:ring-slate-900" />
              )}
            </div>
          </div>
        </div>

        {unreadNotificationsCount > 0 && (
          <div className="flex justify-end">
            <button
              onClick={markAllNotificationsAsRead}
              className="flex items-center gap-1.5 text-xs font-extrabold px-3.5 py-1.5 rounded-full bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800 hover:bg-indigo-100 transition-colors shadow-2xs"
            >
              <CheckCheck size={14} />
              Mark all read
            </button>
          </div>
        )}

        {/* Filter Navigation Bar */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar mt-3 max-w-3xl mx-auto pt-1 pb-1">
          {[
            { id: 'all', label: 'All', icon: Inbox },
            { id: 'unread', label: 'Unread', icon: Bell, badge: unreadNotificationsCount },
            { id: 'campaign', label: 'Campaigns', icon: Briefcase },
            { id: 'financial', label: 'Financial', icon: WalletIcon },
            { id: 'account', label: 'Account', icon: ShieldCheck },
            { id: 'admin', label: 'Broadcasts', icon: Megaphone },
          ].map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-1.5 whitespace-nowrap px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                  isActive
                    ? 'bg-slate-900 text-white dark:bg-white dark:text-slate-900 shadow-sm'
                    : 'bg-slate-100 dark:bg-slate-800/80 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
                {tab.badge ? (
                  <span
                    className={`ml-1 text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                      isActive
                        ? 'bg-rose-500 text-white'
                        : 'bg-rose-100 dark:bg-rose-950 text-rose-600 dark:text-rose-400'
                    }`}
                  >
                    {tab.badge}
                  </span>
                ) : null}
              </button>
            );
          })}
        </div>
      </div>

      {/* Main List Area */}
      <div className="max-w-3xl mx-auto px-4 py-4">
        {filteredNotifications.length === 0 ? (
          <div className="text-center py-16 bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-8 shadow-sm">
            <div className="w-14 h-14 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center mx-auto mb-4 text-slate-400">
              <Inbox className="w-7 h-7" />
            </div>
            <h3 className="text-base font-semibold text-slate-900 dark:text-white mb-1">
              No notifications found
            </h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mx-auto mb-6">
              You're all caught up! Real push notifications triggered by campaigns, withdrawals, or account status changes will appear here instantly.
            </p>
            <button
              onClick={handlePullToRefresh}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-medium transition-colors"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              Check for Updates
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredNotifications.map((notif) => (
              <div
                key={notif.id}
                onClick={() => handleNotificationTap(notif)}
                className={`group relative p-4 rounded-2xl border transition-all cursor-pointer ${
                  notif.isRead
                    ? 'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                    : 'bg-indigo-50/60 dark:bg-indigo-950/30 border-indigo-200 dark:border-indigo-800/60 shadow-sm hover:border-indigo-300 dark:hover:border-indigo-700'
                }`}
              >
                {!notif.isRead && (
                  <div className="absolute top-4 left-2 w-2 h-2 rounded-full bg-indigo-600 animate-ping" />
                )}

                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-start gap-3">
                    <div className="p-2.5 rounded-xl bg-slate-100 dark:bg-slate-800/80 shrink-0 mt-0.5">
                      {getTypeIcon(notif.type)}
                    </div>

                    <div>
                      <div className="flex items-center gap-2 mb-1 flex-wrap">
                        <span className="text-sm font-bold text-slate-900 dark:text-white leading-tight">
                          {notif.title}
                        </span>
                        <span className="text-[10px] px-2 py-0.5 rounded-md font-semibold capitalize bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400">
                          {notif.type.replace(/_/g, ' ')}
                        </span>
                      </div>

                      <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed mb-2">
                        {notif.body || notif.message}
                      </p>

                      <div className="flex items-center gap-3 text-[11px] text-slate-400">
                        <span className="flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {new Date(notif.createdAt).toLocaleTimeString([], {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </span>
                        <span>•</span>
                        <span>
                          {new Date(notif.createdAt).toLocaleDateString([], {
                            month: 'short',
                            day: 'numeric',
                          })}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-1 shrink-0">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteNotification(notif.id);
                      }}
                      className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/50 transition-colors"
                      title="Delete Notification"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                    <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 group-hover:translate-x-1 transition-all" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
