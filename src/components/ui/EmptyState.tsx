import React, { ReactNode } from 'react';

interface EmptyStateProps {
  icon: ReactNode;
  title: string;
  description: string;
  action?: ReactNode;
}

export const EmptyState: React.FC<EmptyStateProps> = ({ icon, title, description, action }) => {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center space-y-3 bg-white dark:bg-slate-900 rounded-3xl border border-slate-100 dark:border-slate-800">
      <div className="w-12 h-12 bg-slate-50 dark:bg-slate-800 rounded-full flex items-center justify-center text-slate-400 dark:text-slate-500 mb-2">
        {icon}
      </div>
      <h3 className="text-sm font-bold text-slate-900 dark:text-white">{title}</h3>
      <p className="text-xs text-slate-500 max-w-sm mx-auto">{description}</p>
      {action && (
        <div className="mt-2">
          {action}
        </div>
      )}
    </div>
  );
};
