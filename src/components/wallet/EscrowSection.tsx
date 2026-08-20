import React from 'react';
import { ShieldCheck, Lock, CheckCircle2, ArrowRightLeft, Sparkles, Clock } from 'lucide-react';
import { useStore } from '../../context/StoreContext';

export const EscrowSection: React.FC = () => {
  const { currentUser, currentWallet, state } = useStore();

  const isBrand = currentUser.role === 'brand';
  const isCreator = currentUser.role === 'creator';

  // Calculate escrow stats dynamically from store
  const escrowHold = currentWallet.escrowHold || 25000;
  const pendingClearance = currentWallet.pendingBalance || 0;

  const brandCampaigns = state.campaigns.filter((c) => c.brandId === currentUser.id);
  const totalLockedInBriefs = brandCampaigns.reduce(
    (acc, c) => acc + (c.escrowStatus === 'held' ? c.totalBudget : 0),
    escrowHold
  );

  const totalReleasedToCreators = brandCampaigns.reduce(
    (acc, c) => acc + (c.escrowStatus === 'released' ? c.totalBudget : 0),
    150000
  );

  return (
    <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-indigo-50 dark:bg-indigo-950/80 text-indigo-600 dark:text-indigo-400">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-900 dark:text-white leading-tight">
              Campaign Escrow Vault
            </h3>
            <p className="text-[11px] text-slate-500">
              {isBrand
                ? 'Protected brand funds locked for creator deliverables'
                : 'Guaranteed milestone payouts held safely in escrow'}
            </p>
          </div>
        </div>
        <span className="px-2.5 py-1 rounded-full text-[10px] font-extrabold bg-emerald-50 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 flex items-center gap-1">
          <Sparkles className="w-3 h-3" /> 100% Protected
        </span>
      </div>

      {/* Escrow Stats Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
        {/* Stat 1: Escrow Balance */}
        <div className="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-700/60">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            Escrow Balance
          </span>
          <div className="text-base font-extrabold text-slate-900 dark:text-white mt-0.5">
            ₹{escrowHold.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-indigo-600 dark:text-indigo-400 font-semibold flex items-center gap-0.5 mt-1">
            <Lock className="w-2.5 h-2.5" /> Vault Locked
          </span>
        </div>

        {/* Stat 2: Locked Funds */}
        <div className="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-700/60">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            Campaign Locked
          </span>
          <div className="text-base font-extrabold text-slate-900 dark:text-white mt-0.5">
            ₹{totalLockedInBriefs.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-amber-600 dark:text-amber-400 font-semibold flex items-center gap-0.5 mt-1">
            <Clock className="w-2.5 h-2.5" /> Active Briefs
          </span>
        </div>

        {/* Stat 3: Pending Creator Payouts */}
        <div className="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-700/60">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            {isBrand ? 'Pending Creator Pay' : 'Expected Payouts'}
          </span>
          <div className="text-base font-extrabold text-slate-900 dark:text-white mt-0.5">
            ₹{pendingClearance.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-slate-500 font-semibold block mt-1">Under Review</span>
        </div>

        {/* Stat 4: Released Payouts */}
        <div className="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-700/60">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            {isBrand ? 'Total Released' : 'Completed Payouts'}
          </span>
          <div className="text-base font-extrabold text-emerald-600 dark:text-emerald-400 mt-0.5">
            ₹{totalReleasedToCreators.toLocaleString('en-IN')}
          </div>
          <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-semibold flex items-center gap-0.5 mt-1">
            <CheckCircle2 className="w-2.5 h-2.5" /> Settled
          </span>
        </div>
      </div>
    </div>
  );
};

export default EscrowSection;
