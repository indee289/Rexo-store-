import React from 'react';
import { TrendingUp, ArrowDownLeft, ArrowUpRight, Clock, Wallet } from 'lucide-react';
import { useStore } from '../../context/StoreContext';

export const WalletAnalytics: React.FC = () => {
  const { currentWallet } = useStore();

  const thisMonthEarnings = 85000;
  const thisMonthWithdrawals = 50000;
  const pendingClearance = currentWallet.pendingBalance || 25000;
  const availableBalance = currentWallet.availableBalance || 175000;

  return (
    <div className="space-y-2">
      <h3 className="text-xs font-extrabold uppercase tracking-wider text-slate-500 px-1">
        Wallet Analytics & Ledger Overview
      </h3>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
        {/* Card 1: This Month Earnings */}
        <div className="p-3.5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              This Month Earned
            </span>
            <div className="p-1 rounded-lg bg-emerald-50 dark:bg-emerald-950 text-emerald-600">
              <TrendingUp className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="text-base font-black text-slate-900 dark:text-white">
            ₹{thisMonthEarnings.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-bold">
            +18.4% vs last month
          </span>
        </div>

        {/* Card 2: This Month Withdrawals */}
        <div className="p-3.5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              This Month Withdrawn
            </span>
            <div className="p-1 rounded-lg bg-indigo-50 dark:bg-indigo-950 text-indigo-600">
              <ArrowUpRight className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="text-base font-black text-slate-900 dark:text-white">
            ₹{thisMonthWithdrawals.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-slate-400 font-medium">Bank Wire Settled</span>
        </div>

        {/* Card 3: Pending Clearance */}
        <div className="p-3.5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              Pending Clearance
            </span>
            <div className="p-1 rounded-lg bg-amber-50 dark:bg-amber-950 text-amber-600">
              <Clock className="w-3.5 h-3.5 animate-pulse" />
            </div>
          </div>
          <div className="text-base font-black text-slate-900 dark:text-white">
            ₹{pendingClearance.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-amber-600 dark:text-amber-400 font-bold">
            Processing Payout
          </span>
        </div>

        {/* Card 4: Available Balance */}
        <div className="p-3.5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-1">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              Available Balance
            </span>
            <div className="p-1 rounded-lg bg-purple-50 dark:bg-purple-950 text-purple-600">
              <Wallet className="w-3.5 h-3.5" />
            </div>
          </div>
          <div className="text-base font-black text-indigo-600 dark:text-indigo-400">
            ₹{availableBalance.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-slate-400 font-medium">Instant Liquid</span>
        </div>
      </div>
    </div>
  );
};

export default WalletAnalytics;
