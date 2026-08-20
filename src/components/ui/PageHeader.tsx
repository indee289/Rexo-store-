import React, { ReactNode } from 'react';

export interface PageHeaderProps {
  title: string;
  actions?: ReactNode;
  showNotificationBell?: boolean;
  onNotificationClick?: () => void;
  notificationCount?: number;
}

export const PageHeader: React.FC<PageHeaderProps> = ({ 
  title, 
  actions,
  showNotificationBell,
  onNotificationClick,
  notificationCount
}) => {
  return (
    <div className="flex items-center justify-between pt-1">
      <div className="flex items-center gap-2.5">
        <img src="/logo.png" alt="Rexo Logo" className="w-8 h-8 rounded-lg object-contain bg-slate-900 shadow-xs border border-slate-800 p-0.5 shrink-0" />
        <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          {title}
        </h1>
      </div>
      <div className="flex items-center gap-2">
        {actions}
      </div>
    </div>
  );
};

export default PageHeader;

