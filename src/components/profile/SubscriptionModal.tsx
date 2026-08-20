import React from 'react';
import { useStore } from '../../context/StoreContext';
import { SubscriptionPlan } from '../../types';
import {
  X,
  Crown,
  CheckCircle2,
  Sparkles,
  ShieldCheck,
  Zap,
} from 'lucide-react';

interface SubscriptionModalProps {
  onClose: () => void;
  onShowToast: (msg: string) => void;
}

export const SubscriptionModal: React.FC<SubscriptionModalProps> = ({
  onClose,
  onShowToast,
}) => {
  const { state, currentUser, subscribeToPlan } = useStore();

  const subscriptionPlans = state.subscriptionPlans || [];
  const userSubscriptions = state.userSubscriptions || [];

  const activeSub = userSubscriptions.find(
    (s) => s.userId === currentUser.id && s.status === 'active'
  );

  const handleSubscribe = (plan: SubscriptionPlan) => {
    const res = subscribeToPlan(plan.id);
    if (res.success) {
      onShowToast(res.message);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-3 sm:p-4 overflow-y-auto">
      <div className="bg-white dark:bg-slate-900 rounded-3xl max-w-lg w-full max-h-[90vh] overflow-y-auto border border-slate-200 dark:border-slate-800 shadow-2xl text-slate-900 dark:text-white relative my-auto p-5 space-y-4">
        {/* MODAL HEADER */}
        <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800/80 pb-3">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-amber-500/10 rounded-2xl text-amber-500">
              <Crown size={22} />
            </div>
            <div>
              <h2 className="text-base font-extrabold text-slate-900 dark:text-white tracking-tight">
                VIP Memberships
              </h2>
              <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">
                Unlock higher earnings, priority brand deals & zero fee payouts
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-all"
          >
            <X size={18} />
          </button>
        </div>

        {/* ACTIVE SUBSCRIPTION BADGE */}
        {activeSub && (
          <div className="p-3.5 bg-amber-500/10 border border-amber-500/30 rounded-2xl flex items-center justify-between text-xs font-bold text-amber-900 dark:text-amber-200">
            <div className="flex items-center gap-2">
              <Crown className="w-4 h-4 text-amber-500" />
              <span>Current Plan: <strong>{activeSub.planName}</strong></span>
            </div>
            <span className="text-[10px] text-amber-600 dark:text-amber-300">
              Active till {new Date(activeSub.expiryDate).toLocaleDateString('en-IN')}
            </span>
          </div>
        )}

        {/* SUBSCRIPTION PLANS LIST */}
        <div className="space-y-3 pt-1">
          {subscriptionPlans.map((plan) => {
            const isSubbed = activeSub?.planId === plan.id;
            return (
              <div
                key={plan.id}
                className={`p-4 rounded-2xl border transition-all ${
                  isSubbed
                    ? 'bg-indigo-900 text-white border-indigo-500 shadow-md'
                    : 'bg-white dark:bg-slate-900 border-slate-200/90 dark:border-slate-800 shadow-2xs'
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <span className="text-[10px] font-black uppercase tracking-wider text-indigo-500 dark:text-indigo-400 block">
                      Membership Plan
                    </span>
                    <h3 className="text-sm font-black text-slate-900 dark:text-white">
                      {plan.name}
                    </h3>
                  </div>
                  <div className="text-right">
                    <span className="text-base font-black text-slate-900 dark:text-white">
                      ₹{plan.price}
                    </span>
                    <span className="text-[10px] text-slate-400 block">/month</span>
                  </div>
                </div>

                <ul className="mt-2.5 space-y-1 text-xs font-medium text-slate-600 dark:text-slate-300">
                  {plan.features.map((feat, idx) => (
                    <li key={idx} className="flex items-center gap-2">
                      <CheckCircle2 size={13} className="text-emerald-500 shrink-0" />
                      <span>{feat}</span>
                    </li>
                  ))}
                </ul>

                <button
                  onClick={() => handleSubscribe(plan)}
                  disabled={isSubbed}
                  className={`w-full mt-3 py-2.5 rounded-xl text-xs font-extrabold transition-all active:scale-95 ${
                    isSubbed
                      ? 'bg-emerald-500 text-white cursor-default'
                      : 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-xs'
                  }`}
                >
                  {isSubbed ? 'Active Membership' : `Subscribe for ₹${plan.price}/mo`}
                </button>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
