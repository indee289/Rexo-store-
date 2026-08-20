import React from 'react';
import {
  X,
  FileText,
  Clock,
  CheckCircle2,
  XCircle,
  Building,
  User,
  ArrowDownLeft,
  ArrowUpRight,
  ExternalLink,
  ShieldCheck,
  Image as ImageIcon,
  Copy,
  Check,
} from 'lucide-react';
import { WalletTransaction } from '../../types';

interface TransactionDetailsModalProps {
  transaction: WalletTransaction | null;
  onClose: () => void;
}

export const TransactionDetailsModal: React.FC<TransactionDetailsModalProps> = ({
  transaction,
  onClose,
}) => {
  const [copied, setCopied] = React.useState(false);

  if (!transaction) return null;

  const isCredit = transaction.direction === 'credit';

  const copyTxId = () => {
    navigator.clipboard.writeText(transaction.id);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const getStatusBadge = () => {
    switch (transaction.status) {
      case 'completed':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 dark:bg-emerald-950/80 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800">
            <CheckCircle2 className="w-3.5 h-3.5" /> Completed
          </span>
        );
      case 'pending':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800 dark:bg-amber-950/80 dark:text-amber-300 border border-amber-200 dark:border-amber-800">
            <Clock className="w-3.5 h-3.5 animate-spin" /> Pending Clearance
          </span>
        );
      case 'failed':
      case 'rejected':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-800 dark:bg-rose-950/80 dark:text-rose-300 border border-rose-200 dark:border-rose-800">
            <XCircle className="w-3.5 h-3.5" /> Rejected
          </span>
        );
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/80 backdrop-blur-md flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in duration-200">
      <div className="w-full max-w-md bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-t-3xl sm:rounded-3xl shadow-2xl p-6 space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
          <div className="flex items-center gap-2.5">
            <div
              className={`bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95`}
            >
              {isCredit ? <ArrowDownLeft className="w-5 h-5" /> : <ArrowUpRight className="w-5 h-5" />}
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white capitalize leading-tight">
                {transaction.type.replace('_', ' ')}
              </h3>
              <p className="text-xs text-slate-500">Transaction Details</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Big Amount Card */}
        <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 text-center space-y-1">
          <div className="flex justify-center">{getStatusBadge()}</div>
          <div
            className={`text-3xl font-black mt-2 ${
              isCredit ? 'text-emerald-600 dark:text-emerald-400' : 'text-slate-900 dark:text-white'
            }`}
          >
            {isCredit ? '+' : '-'} ₹{transaction.amount.toLocaleString('en-IN')}
          </div>
          <p className="text-xs text-slate-500 font-medium">
            {new Date(transaction.createdAt).toLocaleString('en-IN', {
              dateStyle: 'medium',
              timeStyle: 'short',
            })}
          </p>
        </div>

        {/* Transaction Metadata Grid */}
        <div className="space-y-3 text-xs">
          {/* TX ID */}
          <div className="flex items-center justify-between p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/60">
            <span className="text-slate-500 font-medium">Transaction ID</span>
            <div className="flex items-center gap-1.5">
              <span className="font-mono font-bold text-slate-900 dark:text-white">
                {transaction.id}
              </span>
              <button
                onClick={copyTxId}
                className="p-1 rounded bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300 hover:text-indigo-600"
              >
                {copied ? <Check className="w-3 h-3 text-emerald-600" /> : <Copy className="w-3 h-3" />}
              </button>
            </div>
          </div>

          {/* Reference ID if available */}
          {transaction.referenceId && (
            <div className="flex items-center justify-between p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/60">
              <span className="text-slate-500 font-medium">Bank / UTR Reference</span>
              <span className="font-mono font-bold text-slate-900 dark:text-white">
                {transaction.referenceId}
              </span>
            </div>
          )}

          {/* Counterparty / Channel */}
          {transaction.counterpartyName && (
            <div className="flex items-center justify-between p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/60">
              <span className="text-slate-500 font-medium">Counterparty / Bank</span>
              <span className="font-bold text-slate-900 dark:text-white">
                {transaction.counterpartyName}
              </span>
            </div>
          )}

          {/* Campaign Brief if linked */}
          {transaction.campaignTitle && (
            <div className="flex items-center justify-between p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/60">
              <span className="text-slate-500 font-medium">Campaign Brief</span>
              <span className="font-bold text-indigo-600 dark:text-indigo-400">
                {transaction.campaignTitle}
              </span>
            </div>
          )}

          {/* Note */}
          <div className="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/60 space-y-1">
            <span className="text-slate-500 font-medium block">Description / Notes</span>
            <p className="font-medium text-slate-900 dark:text-white leading-relaxed">
              {transaction.note}
            </p>
          </div>

          {/* Proof Screenshot if attached */}
          {transaction.proofScreenshotUrl && (
            <div className="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200/80 dark:border-slate-700/60 space-y-2">
              <span className="text-slate-500 font-medium flex items-center gap-1.5">
                <ImageIcon className="w-3.5 h-3.5 text-indigo-600" /> Deposit Proof Screenshot
              </span>
              <img
                src={transaction.proofScreenshotUrl}
                alt="Deposit Proof"
                className="w-full h-36 object-cover rounded-xl border"
              />
            </div>
          )}

          {/* Admin Remarks */}
          {transaction.adminRemarks && (
            <div className="p-3 rounded-2xl bg-amber-50/70 dark:bg-amber-950/30 border border-amber-200/80 dark:border-amber-800/50 text-amber-900 dark:text-amber-200 space-y-1">
              <span className="text-[10px] font-bold uppercase tracking-wider block text-amber-700 dark:text-amber-400">
                Admin Clearance Remarks
              </span>
              <p className="font-medium text-xs">{transaction.adminRemarks}</p>
            </div>
          )}
        </div>

        <button
          onClick={onClose}
          className="w-full py-2 rounded-xl bg-slate-900 dark:bg-slate-800 text-white font-bold text-xs hover:bg-slate-800 dark:hover:bg-slate-700 transition-all"
        >
          Close Details
        </button>
      </div>
    </div>
  );
};

export default TransactionDetailsModal;
