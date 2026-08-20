import React from 'react';

interface FilterPillProps {
  label: string;
  isActive: boolean;
  onClick: () => void;
  count?: number;
}

export const FilterPill: React.FC<FilterPillProps> = ({ label, isActive, onClick, count }) => {
  return (
    <button
      onClick={onClick}
      className={`px-4 py-1.5 rounded-full text-[13px] font-bold whitespace-nowrap transition-all shadow-xs flex items-center gap-1.5 ${
        isActive
          ? 'bg-slate-900 text-white dark:bg-white dark:text-slate-900'
          : 'bg-white text-slate-600 border border-slate-200 dark:bg-slate-900 dark:text-slate-300 dark:border-slate-800'
      }`}
    >
      {label}
      {count !== undefined && (
        <span className={`px-1.5 py-0.5 rounded-full text-[10px] ${
          isActive 
            ? 'bg-white/20 dark:bg-slate-900/20' 
            : 'bg-slate-100 dark:bg-slate-800 text-slate-500'
        }`}>
          {count}
        </span>
      )}
    </button>
  );
};

export default FilterPill;
