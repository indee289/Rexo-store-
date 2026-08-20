import React, { useState } from 'react';
import {
  ShieldCheck,
  CheckCircle2,
  XCircle,
  Clock,
  ArrowUpRight,
  Building,
  User,
  AlertTriangle,
  Lock,
  Unlock,
  DollarSign,
  FileText,
  Search,
  Check,
  X,
  Eye,
} from 'lucide-react';
import { useStore } from '../../context/StoreContext';
import { WithdrawalRequest, DepositRequest } from '../../types';

export const AdminWalletApprovalView: React.FC = () => {
  const {
    state,
    currentUser,
    adminProcessWithdrawal,
    adminProcessDeposit,
    adminAdjustUserWallet,
    adminSetWalletFreeze,
  } = useStore();

  const [activeTab, setActiveTab] = useState<'withdrawals' | 'deposits' | 'adjust' | 'audit'>('withdrawals');
  const [selectedProofImg, setSelectedProofImg] = useState<string | null>(null);

  // Adjustment State
  const [targetUserId, setTargetUserId] = useState<string>(state.users[0]?.id || '');
  const [adjustAmount, setAdjustAmount] = useState<number>(1000);
  const [adjustDirection, setAdjustDirection] = useState<'credit' | 'debit'>('credit');
  const [adjustNote, setAdjustNote] = useState<string>('Performance Bonus');
  const [adjustReason, setAdjustReason] = useState<string>('Q3 Marketing Incentive');
  const [adjustFeedback, setAdjustFeedback] = useState<string | null>(null);

  const pendingWithdrawals = state.withdrawals.filter((w) => w.status === 'pending');
  const pendingDeposits = state.deposits.filter((d) => d.status === 'pending');

  const handleAdjustSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!targetUserId || adjustAmount <= 0) return;
    adminAdjustUserWallet(targetUserId, adjustAmount, adjustDirection, adjustNote, adjustReason);
    setAdjustFeedback(`Successfully ${adjustDirection}ed ₹${adjustAmount.toLocaleString('en-IN')}!`);
    setTimeout(() => setAdjustFeedback(null), 3500);
  };

  return (
    <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
        <div className="flex items-center gap-2.5">
          <div className="p-2.5 rounded-xl bg-purple-600 text-white">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-900 dark:text-white leading-tight">
              Admin Financial Control Center
            </h3>
            <p className="text-[11px] text-slate-500">Approve payouts, clear deposits & audit ledger</p>
          </div>
        </div>
        <span className="px-2.5 py-1 rounded-full text-[10px] font-extrabold bg-purple-100 dark:bg-purple-950 text-purple-700 dark:text-purple-300">
          Super Admin Mode
        </span>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1.5 border-b border-slate-100 dark:border-slate-800 pb-2 overflow-x-auto no-scrollbar">
        {[
          { id: 'withdrawals', label: `Pending Withdrawals (${pendingWithdrawals.length})` },
          { id: 'deposits', label: `Pending Deposits (${pendingDeposits.length})` },
          { id: 'adjust', label: 'Manual Balance Adjust' },
          { id: 'audit', label: 'Financial Audit Logs' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
              activeTab === tab.id
                ? 'bg-slate-900 text-white dark:bg-white dark:text-slate-900 shadow-sm'
                : 'text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* TAB 1: PENDING WITHDRAWALS */}
      {activeTab === 'withdrawals' && (
        <div className="space-y-3">
          {pendingWithdrawals.length === 0 ? (
            <div className="text-center py-8 text-slate-400 text-xs font-medium">
              No pending withdrawal requests. All payouts cleared!
            </div>
          ) : (
            pendingWithdrawals.map((w) => (
              <div
                key={w.id}
                className="p-4 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
              >
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="font-extrabold text-slate-900 dark:text-white">{w.userName}</span>
                    <span className="text-[10px] px-1.5 py-0.2 rounded font-bold bg-indigo-100 text-indigo-700 uppercase">
                      {w.userRole}
                    </span>
                  </div>
                  <div className="text-base font-black text-slate-900 dark:text-white">
                    ₹{w.amount.toLocaleString('en-IN')}
                  </div>
                  <p className="text-[11px] text-slate-500">
                    Bank: <strong className="text-slate-700 dark:text-slate-300">{w.payoutDetails.bankName || 'UPI'}</strong> • A/C:{' '}
                    <span className="font-mono">{w.payoutDetails.accountNumber || w.payoutDetails.upiId}</span> • IFSC:{' '}
                    <span className="font-mono">{w.payoutDetails.ifscCode || 'N/A'}</span>
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => adminProcessWithdrawal(w.id, 'approved', 'IMPS Payout Cleared by Admin')}
                    className="px-3 py-2 rounded-xl bg-emerald-600 text-white font-bold text-xs hover:bg-emerald-700 flex items-center gap-1 shadow-sm active:scale-95 transition-all"
                  >
                    <Check className="w-3.5 h-3.5" /> Approve Payout
                  </button>
                  <button
                    onClick={() => adminProcessWithdrawal(w.id, 'rejected', 'Verification details mismatched')}
                    className="px-3 py-2 rounded-xl bg-rose-50 text-rose-600 dark:bg-rose-950/80 font-bold text-xs hover:bg-rose-100 flex items-center gap-1 active:scale-95 transition-all"
                  >
                    <X className="w-3.5 h-3.5" /> Reject
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* TAB 2: PENDING DEPOSITS */}
      {activeTab === 'deposits' && (
        <div className="space-y-3">
          {pendingDeposits.length === 0 ? (
            <div className="text-center py-8 text-slate-400 text-xs font-medium">
              No pending brand deposit requests.
            </div>
          ) : (
            pendingDeposits.map((d) => (
              <div
                key={d.id}
                className="p-4 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
              >
                <div className="space-y-1">
                  <span className="font-extrabold text-slate-900 dark:text-white">{d.brandName}</span>
                  <div className="text-base font-black text-emerald-600 dark:text-emerald-400">
                    +₹{d.amount.toLocaleString('en-IN')}
                  </div>
                  <p className="text-[11px] text-slate-500">
                    Method: <strong className="text-slate-700 dark:text-slate-300">{d.paymentMethod}</strong> • UTR Ref:{' '}
                    <span className="font-mono font-bold text-slate-900 dark:text-white">{d.transactionRef}</span>
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  {d.proofScreenshotUrl && (
                    <button
                      onClick={() => setSelectedProofImg(d.proofScreenshotUrl!)}
                      className="px-2.5 py-2 rounded-xl bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-200 font-bold text-xs flex items-center gap-1"
                    >
                      <Eye className="w-3.5 h-3.5" /> View Proof
                    </button>
                  )}
                  <button
                    onClick={() => adminProcessDeposit(d.id, 'approved')}
                    className="px-3 py-2 rounded-xl bg-emerald-600 text-white font-bold text-xs hover:bg-emerald-700 flex items-center gap-1 shadow-sm active:scale-95 transition-all"
                  >
                    <Check className="w-3.5 h-3.5" /> Confirm Deposit
                  </button>
                  <button
                    onClick={() => adminProcessDeposit(d.id, 'rejected')}
                    className="px-3 py-2 rounded-xl bg-rose-50 text-rose-600 dark:bg-rose-950/80 font-bold text-xs hover:bg-rose-100 flex items-center gap-1 active:scale-95 transition-all"
                  >
                    <X className="w-3.5 h-3.5" /> Reject
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* TAB 3: MANUAL BALANCE ADJUSTMENT */}
      {activeTab === 'adjust' && (
        <form onSubmit={handleAdjustSubmit} className="space-y-3.5 text-xs">
          {adjustFeedback && (
            <div className="p-3 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-800 font-bold text-xs">
              {adjustFeedback}
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Select Target User
              </label>
              <select
                value={targetUserId}
                onChange={(e) => setTargetUserId(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white font-semibold"
              >
                {state.users.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.name} (@{u.username}) - {u.role.toUpperCase()}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Adjustment Direction
              </label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setAdjustDirection('credit')}
                  className={`py-2 rounded-xl font-bold border transition-all ${
                    adjustDirection === 'credit'
                      ? 'bg-emerald-600 text-white border-emerald-600'
                      : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'
                  }`}
                >
                  + Credit
                </button>
                <button
                  type="button"
                  onClick={() => setAdjustDirection('debit')}
                  className={`py-2 rounded-xl font-bold border transition-all ${
                    adjustDirection === 'debit'
                      ? 'bg-rose-600 text-white border-rose-600'
                      : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'
                  }`}
                >
                  - Debit
                </button>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Amount (INR ₹)
              </label>
              <input
                type="number"
                value={adjustAmount}
                onChange={(e) => setAdjustAmount(Number(e.target.value))}
                className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white font-bold"
              />
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Note / Description
              </label>
              <input
                type="text"
                value={adjustNote}
                onChange={(e) => setAdjustNote(e.target.value)}
                placeholder="e.g. Campaign Incentive Bonus"
                className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white font-semibold"
              />
            </div>
          </div>

          <button
            type="submit"
            className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
          >
            Execute Balance Adjustment
          </button>
        </form>
      )}

      {/* TAB 4: AUDIT LOGS */}
      {activeTab === 'audit' && (
        <div className="space-y-2 text-xs">
          {state.auditLogs.length === 0 ? (
            <div className="text-center py-6 text-slate-400">No financial audit logs recorded.</div>
          ) : (
            state.auditLogs.slice(0, 10).map((log) => (
              <div
                key={log.id}
                className="p-3 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/40 flex items-center justify-between"
              >
                <div>
                  <span className="font-extrabold text-slate-900 dark:text-white">{log.action}</span>
                  <p className="text-[10px] text-slate-500">
                    By Admin: {log.adminName} • Target: {log.targetName || log.targetId}
                  </p>
                </div>
                <span className="text-[10px] text-slate-400 font-mono">
                  {new Date(log.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>
            ))
          )}
        </div>
      )}

      {/* Proof Image Viewer Lightbox */}
      {selectedProofImg && (
        <div
          onClick={() => setSelectedProofImg(null)}
          className="fixed inset-0 z-50 bg-slate-950/90 backdrop-blur-md flex items-center justify-center p-4 cursor-pointer"
        >
          <div className="max-w-lg w-full bg-slate-900 border border-slate-800 rounded-3xl p-4 space-y-3">
            <div className="flex items-center justify-between text-white">
              <span className="text-xs font-bold">Deposit Receipt Proof</span>
              <X className="w-5 h-5 text-slate-400" />
            </div>
            <img src={selectedProofImg} alt="Proof" className="w-full rounded-2xl max-h-[70vh] object-contain" />
          </div>
        </div>
      )}
    </div>
  );
};
