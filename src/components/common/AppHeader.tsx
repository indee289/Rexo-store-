import React from 'react';
import { useStore } from '../../context/StoreContext';
import { Wallet, Bell, Sparkles, UserCheck, ShieldCheck, Briefcase } from 'lucide-react';

interface AppHeaderProps {
  onOpenNotifications: () => void;
  onOpenRoleSwitcher: () => void;
}

export const AppHeader: React.FC<AppHeaderProps> = ({
  onOpenNotifications,
  onOpenRoleSwitcher,
}) => {
  const { currentUser, currentWallet, unreadNotificationsCount } = useStore();

  const getRoleBadge = () => {
    switch (currentUser.role) {
      case 'brand':
        return { label: 'Brand', bg: 'bg-purple-50 text-purple-700 border-purple-200', icon: Briefcase };
      case 'admin':
        return { label: 'Admin', bg: 'bg-rose-50 text-rose-700 border-rose-200', icon: ShieldCheck };
      default:
        return { label: 'Creator', bg: 'bg-indigo-50 text-indigo-700 border-indigo-200', icon: UserCheck };
    }
  };

  const roleInfo = getRoleBadge();
  const RoleIcon = roleInfo.icon;

  return (
    <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200/80 px-4 py-2.5">
      <div className="max-w-2xl mx-auto flex items-center justify-between">
        {/* APP BRANDING & ROLE SWITCH TRIGGER */}
        <div className="flex items-center gap-2.5">
          <div className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95">
            R
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-extrabold text-sm tracking-tight text-slate-900">Rexo Market</span>
              <button
                onClick={onOpenRoleSwitcher}
                className={`text-[10px] font-bold px-2 py-0.5 rounded-full border flex items-center gap-1 active:scale-95 transition-all ${roleInfo.bg}`}
                title="Click to Switch Role"
              >
                <RoleIcon size={11} />
                {roleInfo.label}
              </button>
            </div>
            <p className="text-[11px] font-medium text-slate-500 truncate max-w-[140px] sm:max-w-[200px]">
              {currentUser.name}
            </p>
          </div>
        </div>

        {/* WALLET BALANCE & NOTIFICATIONS */}
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200/80 px-3 py-1.5 rounded-xl shadow-2xs">
            <Wallet size={14} className="text-emerald-600" />
            <span className="text-xs font-extrabold text-slate-900">
              ₹{currentWallet.availableBalance.toLocaleString()}
            </span>
          </div>

          <button
            onClick={onOpenNotifications}
            className="relative p-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 border border-slate-200/80 text-slate-700 active:scale-95 transition-all"
            title="Notifications"
          >
            <Bell size={18} />
            {unreadNotificationsCount > 0 && (
              <span className="absolute -top-1 -right-1 w-4 h-4 z-10 bg-rose-600 text-white text-[10px] font-black rounded-full flex items-center justify-center animate-pulse">
                {unreadNotificationsCount}
              </span>
            )}
          </button>
        </div>
      </div>
    </header>
  );
};
