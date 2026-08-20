import React from 'react';

export const Skeleton = ({ className }: { className?: string }) => {
  return (
    <div className={`animate-pulse bg-slate-200 dark:bg-slate-800 rounded-xl ${className}`} />
  );
};

export const CardSkeleton = () => (
  <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4">
    <div className="flex items-center gap-3">
      <Skeleton className="w-12 h-12 rounded-2xl" />
      <div className="space-y-2 flex-1">
        <Skeleton className="h-4 w-3/4" />
        <Skeleton className="h-3 w-1/2" />
      </div>
    </div>
    <div className="space-y-2 pt-2">
      <Skeleton className="h-3 w-full" />
      <Skeleton className="h-3 w-5/6" />
    </div>
    <div className="pt-2 flex justify-between">
      <Skeleton className="h-8 w-24 rounded-lg" />
      <Skeleton className="h-8 w-24 rounded-lg" />
    </div>
  </div>
);

export const TransactionSkeleton = () => (
  <div className="p-4 flex items-center justify-between">
    <div className="flex items-center gap-3">
      <Skeleton className="w-10 h-10 rounded-2xl" />
      <div className="space-y-2">
        <Skeleton className="h-4 w-32" />
        <Skeleton className="h-3 w-20" />
      </div>
    </div>
    <div className="space-y-2 text-right flex flex-col items-end">
      <Skeleton className="h-4 w-16" />
      <Skeleton className="h-3 w-12" />
    </div>
  </div>
);
