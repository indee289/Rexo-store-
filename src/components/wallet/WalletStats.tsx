import React from 'react';
import { ShieldCheck, Clock, TrendingUp } from 'lucide-react';
import { useStore } from '../../context/StoreContext';

export const WalletStats: React.FC = () => {
  const { currentWallet } = useStore();

  const escrowAmount = currentWallet.escrowHold ?? 25000;
  const pendingAmount = currentWallet.pendingBalance ?? 10000;
  const earningsAmount = currentWallet.totalEarned ?? 450000;

  return (
    <div className="grid grid-cols-3 gap-2.5 max-w-md mx-auto pt-1">
      {/* Escrow Card */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-3 shadow-2xs hover:shadow-xs transition-all flex flex-col justify-between space-y-1">
        <div className="flex items-center gap-1.5 text-indigo-600 dark:text-indigo-400">
          <ShieldCheck size={14} />
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Escrow
          </span>
        </div>
        <div className="text-sm sm:text-base font-black text-slate-900 dark:text-white tracking-tight">
          ₹{escrowAmount.toLocaleString('en-IN')}
        </div>
      </div>

      {/* Pending Card */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-3 shadow-2xs hover:shadow-xs transition-all flex flex-col justify-between space-y-1">
        <div className="flex items-center gap-1.5 text-amber-500">
          <Clock size={14} />
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Pending
          </span>
        </div>
        <div className="text-sm sm:text-base font-black text-slate-900 dark:text-white tracking-tight">
          ₹{pendingAmount.toLocaleString('en-IN')}
        </div>
      </div>

      {/* Earnings Card */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-3 shadow-2xs hover:shadow-xs transition-all flex flex-col justify-between space-y-1">
        <div className="flex items-center gap-1.5 text-emerald-500">
          <TrendingUp size={14} />
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Earnings
          </span>
        </div>
        <div className="text-sm sm:text-base font-black text-slate-900 dark:text-white tracking-tight">
          ₹{earningsAmount.toLocaleString('en-IN')}
        </div>
      </div>
    </div>
  );
};

export default WalletStats;
