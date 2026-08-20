import React from 'react';
import { Home, Flag, Wallet, ShoppingBag, User } from 'lucide-react';

interface BottomNavigationProps {
  activeTab: string;
  onTabChange: (tabId: string) => void;
  unreadNotificationsCount?: number;
}

export const BottomNavigation: React.FC<BottomNavigationProps> = ({
  activeTab,
  onTabChange,
  unreadNotificationsCount
}) => {
  const tabs = [
    { id: 'home', label: 'Home', icon: Home },
    { id: 'campaigns', label: 'Campaigns', icon: Flag },
    { id: 'wallet', label: 'Wallet', icon: Wallet },
    { id: 'shop', label: 'Shop', icon: ShoppingBag },
    { id: 'profile', label: 'Profile', icon: User },
  ];

  return (
    <div 
      className="fixed bottom-0 left-0 right-0 z-40 pointer-events-none px-4 sm:px-6"
      style={{ paddingBottom: 'calc(env(safe-area-inset-bottom) + 16px)' }}
    >
      <div className="mx-auto max-w-md bg-white/80 backdrop-blur-2xl border border-white/40 shadow-[0_8px_32px_rgba(0,0,0,0.08)] rounded-full px-2 py-2 flex items-center justify-between pointer-events-auto">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={`relative flex flex-col items-center justify-center flex-1 min-w-0 py-2.5 rounded-2xl transition-all duration-300 ease-out active:scale-90 ${
                isActive ? 'text-slate-900' : 'text-slate-400 hover:text-slate-600'
              }`}
            >
              {isActive && (
                <div className="absolute inset-0 bg-slate-900/5 rounded-[20px] -z-10 transition-all duration-300 scale-100" />
              )}
              
              <Icon 
                className={`w-[22px] h-[22px] mb-1 transition-all duration-300 ${
                  isActive ? 'stroke-[2.5px] scale-110' : 'stroke-[2px]'
                }`} 
              />
              <span className={`text-[10px] tracking-wide transition-all duration-300 ${
                isActive ? 'font-semibold opacity-100' : 'font-medium opacity-80'
              }`}>
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
