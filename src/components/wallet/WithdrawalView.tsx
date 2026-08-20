import React, { useState } from 'react';
import {
  ArrowLeft,
  ArrowUpRight,
  Building,
  ShieldCheck,
  AlertCircle,
  QrCode,
  Check,
  Lock,
  Sparkles,
} from 'lucide-react';
import { SlideToConfirm } from './SlideToConfirm';
import { SecurityVerificationModal } from './SecurityVerificationModal';
import { useStore } from '../../context/StoreContext';

interface WithdrawalViewProps {
  onBack: () => void;
  onSuccess: (msg: string) => void;
}

export const WithdrawalView: React.FC<WithdrawalViewProps> = ({ onBack, onSuccess }) => {
  const { currentWallet, requestWithdrawal, systemSettings } = useStore();

  const [amount, setAmount] = useState<number>(Math.min(10000, currentWallet.availableBalance || 0));
  const [bankName, setBankName] = useState<string>('HDFC Bank');
  const [accountHolderName, setAccountHolderName] = useState<string>('TechRexo Global Creator');
  const [accountNumber, setAccountNumber] = useState<string>('998811223344');
  const [ifscCode, setIfscCode] = useState<string>('HDFC0001234');
  const [upiId, setUpiId] = useState<string>('creator@upi');
  const [withdrawMethod, setWithdrawMethod] = useState<'Bank' | 'UPI'>('Bank');

  const [isSecurityModalOpen, setIsSecurityModalOpen] = useState<boolean>(false);
  const [isSecurityVerified, setIsSecurityVerified] = useState<boolean>(false);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [resetSliderSignal, setResetSliderSignal] = useState(0);

  const maxWithdrawal = currentWallet.availableBalance || 0;
  const minWithdrawal = systemSettings.minimumWithdrawalAmount || 500;

  const isFormValid =
    amount >= minWithdrawal &&
    amount <= maxWithdrawal &&
    accountHolderName.trim().length > 2 &&
    (withdrawMethod === 'Bank' ? accountNumber.trim().length > 5 && ifscCode.trim().length > 4 : upiId.trim().length > 3);

  const handleSlideConfirmInitiate = () => {
    if (!isFormValid) {
      setResetSliderSignal((prev) => prev + 1);
      return;
    }

    if (!isSecurityVerified) {
      setIsSecurityModalOpen(true);
      return;
    }

    executeWithdrawal();
  };

  const executeWithdrawal = () => {
    setIsSubmitting(true);

    setTimeout(() => {
      const res = requestWithdrawal(amount, withdrawMethod, {
        bankName,
        accountHolderName,
        accountNumber,
        ifscCode,
        upiId,
      });

      setIsSubmitting(false);

      if (res.success) {
        onSuccess(res.message);
        onBack();
      } else {
        alert(res.message);
        setResetSliderSignal((prev) => prev + 1);
      }
    }, 600);
  };

  const handleSecurityVerified = () => {
    setIsSecurityVerified(true);
    setIsSecurityModalOpen(false);
    executeWithdrawal();
  };

  return (
    <div className="min-h-screen bg-[#F4F6F9] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans">
      <div className="max-w-md mx-auto px-4 space-y-5">
        
        {/* HEADER WITH BACK BUTTON */}
        <div className="flex items-center gap-3 pt-1">
          <button
            onClick={onBack}
            className="p-2 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-50 transition-all active:scale-95"
          >
            <ArrowLeft size={18} />
          </button>
          <div>
            <h1 className="text-base font-extrabold text-slate-900 dark:text-white leading-tight">
              Request Payout Withdrawal
            </h1>
            <p className="text-[11px] font-medium text-slate-400">
              Withdraw balance directly to Bank / UPI
            </p>
          </div>
        </div>

        {/* COMPACT AVAILABLE BALANCE CARD */}
        <div className="p-3.5 rounded-2xl bg-indigo-50/80 dark:bg-indigo-950/40 border border-indigo-100 dark:border-indigo-900/60 flex items-center justify-between">
          <div>
            <span className="text-[10px] text-indigo-700 dark:text-indigo-300 font-bold uppercase tracking-wider block">
              Available for Withdrawal
            </span>
            <div className="text-lg font-bold text-indigo-950 dark:text-white">
              ₹{maxWithdrawal.toLocaleString('en-IN')}
            </div>
          </div>
          <button
            type="button"
            onClick={() => setAmount(maxWithdrawal)}
            className="px-3 py-1.5 rounded-xl bg-indigo-600 text-white text-xs font-bold hover:bg-indigo-700 transition-all active:scale-95 shadow-xs"
          >
            Withdraw All
          </button>
        </div>

        {/* WITHDRAWAL AMOUNT INPUT */}
        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200/80 dark:border-slate-800 space-y-2 shadow-2xs">
          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider">
            Withdrawal Amount (INR ₹)
          </label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-lg font-bold text-indigo-600">
              ₹
            </span>
            <input
              type="number"
              value={amount || ''}
              onChange={(e) => setAmount(Number(e.target.value))}
              placeholder="0"
              className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl pl-8 pr-3 py-2.5 text-base font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/30"
            />
          </div>

          <div className="flex items-center justify-between text-[11px] font-medium pt-0.5">
            <span className="text-slate-400">Min: ₹{minWithdrawal}</span>
            {amount > maxWithdrawal && (
              <span className="text-rose-500 font-bold flex items-center gap-1">
                <AlertCircle size={12} /> Exceeds available balance
              </span>
            )}
          </div>
        </div>

        {/* PAYOUT CHANNEL SELECTOR */}
        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200/80 dark:border-slate-800 space-y-2.5 shadow-2xs">
          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider">
            Payout Channel
          </label>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => setWithdrawMethod('Bank')}
              className={`p-3 rounded-xl border text-xs font-bold transition-all text-left flex items-center gap-2 ${
                withdrawMethod === 'Bank'
                  ? 'border-indigo-600 bg-indigo-50/80 text-indigo-900 dark:bg-indigo-950/50 dark:text-indigo-200'
                  : 'border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
              }`}
            >
              <Building size={16} className="text-indigo-600" />
              <span>Bank Wire (IMPS/NEFT)</span>
            </button>

            <button
              type="button"
              onClick={() => setWithdrawMethod('UPI')}
              className={`p-3 rounded-xl border text-xs font-bold transition-all text-left flex items-center gap-2 ${
                withdrawMethod === 'UPI'
                  ? 'border-indigo-600 bg-indigo-50/80 text-indigo-900 dark:bg-indigo-950/50 dark:text-indigo-200'
                  : 'border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
              }`}
            >
              <QrCode size={16} className="text-indigo-600" />
              <span>Direct UPI Transfer</span>
            </button>
          </div>
        </div>

        {/* ACCOUNT DETAILS INPUTS */}
        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200/80 dark:border-slate-800 space-y-3 shadow-2xs">
          <div>
            <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
              Account Holder Name *
            </label>
            <input
              type="text"
              value={accountHolderName}
              onChange={(e) => setAccountHolderName(e.target.value)}
              className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs font-bold text-slate-900 dark:text-white"
            />
          </div>

          {withdrawMethod === 'Bank' ? (
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                  Bank Name *
                </label>
                <input
                  type="text"
                  value={bankName}
                  onChange={(e) => setBankName(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs font-bold text-slate-900 dark:text-white"
                />
              </div>
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                  IFSC Code *
                </label>
                <input
                  type="text"
                  value={ifscCode}
                  onChange={(e) => setIfscCode(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs font-bold text-slate-900 dark:text-white uppercase"
                />
              </div>
              <div className="col-span-2">
                <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                  Account Number *
                </label>
                <input
                  type="text"
                  value={accountNumber}
                  onChange={(e) => setAccountNumber(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs font-bold text-slate-900 dark:text-white"
                />
              </div>
            </div>
          ) : (
            <div>
              <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                UPI ID / VPA *
              </label>
              <input
                type="text"
                value={upiId}
                onChange={(e) => setUpiId(e.target.value)}
                placeholder="username@upi"
                className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs font-bold text-slate-900 dark:text-white"
              />
            </div>
          )}
        </div>

        {/* SLIDE TO CONFIRM */}
        <div className="pt-2">
          <SlideToConfirm
            onConfirm={handleSlideConfirmInitiate}
            disabled={!isFormValid || isSubmitting}
            resetSignal={resetSliderSignal}
            text={
              !isFormValid
                ? 'FILL REQUIRED DETAILS ABOVE'
                : isSubmitting
                ? 'PROCESSING WITHDRAWAL...'
                : 'SLIDE TO CONFIRM WITHDRAWAL'
            }
          />
        </div>

      </div>

      {isSecurityModalOpen && (
        <SecurityVerificationModal
          isOpen={isSecurityModalOpen}
          onClose={() => setIsSecurityModalOpen(false)}
          onVerified={handleSecurityVerified}
        />
      )}
    </div>
  );
};

export default WithdrawalView;
