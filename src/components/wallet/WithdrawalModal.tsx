import React, { useState } from 'react';
import {
  X,
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

interface WithdrawalModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (msg: string) => void;
}

export const WithdrawalModal: React.FC<WithdrawalModalProps> = ({ isOpen, onClose, onSuccess }) => {
  const { currentWallet, requestWithdrawal, systemSettings } = useStore();

  const [amount, setAmount] = useState<number>(10000);
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

  if (!isOpen) return null;

  const maxWithdrawal = currentWallet.availableBalance;
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

    // Trigger Security Verification PIN Modal first!
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
        onClose();
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
    <>
      <div className="fixed inset-0 z-50 bg-slate-900/80 backdrop-blur-md flex items-end sm:items-center justify-center p-0 sm:p-4 overflow-y-auto animate-in fade-in duration-200">
        <div className="w-full max-w-lg bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-t-3xl sm:rounded-3xl shadow-2xl flex flex-col max-h-[92vh]">
          {/* Modal Header */}
          <div className="sticky top-0 z-20 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between rounded-t-3xl">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-gradient-to-tr from-purple-600 to-indigo-600 text-white shadow-md">
                <ArrowUpRight className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-bold text-slate-900 dark:text-white leading-tight">
                  Request Payout Withdrawal
                </h2>
                <p className="text-xs text-slate-500">Withdraw available balance directly to Bank / UPI</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Modal Body */}
          <div className="p-6 overflow-y-auto space-y-5 flex-1">
            {/* Available Balance Helper Badge */}
            <div className="p-4 rounded-2xl bg-indigo-50/60 dark:bg-indigo-950/40 border border-indigo-100 dark:border-indigo-900 flex items-center justify-between">
              <div>
                <span className="text-xs text-indigo-700 dark:text-indigo-300 font-medium">
                  Available for Withdrawal
                </span>
                <div className="text-xl font-extrabold text-indigo-950 dark:text-white">
                  ₹{maxWithdrawal.toLocaleString('en-IN')}
                </div>
              </div>
              <button
                type="button"
                onClick={() => setAmount(maxWithdrawal)}
                className="px-3 py-1.5 rounded-xl bg-indigo-600 text-white text-xs font-bold hover:bg-indigo-700 shadow-sm transition-all"
              >
                Withdraw All
              </button>
            </div>

            {/* Withdrawal Amount Field */}
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                Withdrawal Amount (INR ₹)
              </label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-2xl font-black text-indigo-600">
                  ₹
                </span>
                <input
                  type="number"
                  value={amount || ''}
                  onChange={(e) => setAmount(Number(e.target.value))}
                  placeholder="Enter amount"
                  className="w-full pl-10 pr-4 py-3.5 rounded-2xl border-2 border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xl font-bold focus:border-indigo-600 focus:outline-none transition-all"
                />
              </div>
              <div className="flex items-center justify-between mt-1 text-[11px] text-slate-500">
                <span>Min: ₹{minWithdrawal.toLocaleString('en-IN')}</span>
                {amount > maxWithdrawal && (
                  <span className="text-rose-500 font-bold flex items-center gap-1">
                    <AlertCircle className="w-3 h-3" /> Exceeds available balance
                  </span>
                )}
              </div>
            </div>

            {/* Payout Method Toggle */}
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                Payout Channel
              </label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setWithdrawMethod('Bank')}
                  className={`p-3 rounded-2xl border-2 text-left transition-all flex items-center gap-2.5 ${
                    withdrawMethod === 'Bank'
                      ? 'border-indigo-600 bg-indigo-50/50 dark:bg-indigo-950/40 text-indigo-900 dark:text-indigo-200 shadow-sm'
                      : 'border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-800/50 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  <Building className="w-5 h-5 text-indigo-600" />
                  <span className="text-xs font-bold">Bank Wire (IMPS / NEFT)</span>
                </button>
                <button
                  type="button"
                  onClick={() => setWithdrawMethod('UPI')}
                  className={`p-3 rounded-2xl border-2 text-left transition-all flex items-center gap-2.5 ${
                    withdrawMethod === 'UPI'
                      ? 'border-indigo-600 bg-indigo-50/50 dark:bg-indigo-950/40 text-indigo-900 dark:text-indigo-200 shadow-sm'
                      : 'border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-800/50 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  <QrCode className="w-5 h-5 text-indigo-600" />
                  <span className="text-xs font-bold">Direct UPI Transfer</span>
                </button>
              </div>
            </div>

            {/* Bank / UPI Detail Inputs */}
            <div className="space-y-3.5">
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                  Account Holder Name *
                </label>
                <input
                  type="text"
                  value={accountHolderName}
                  onChange={(e) => setAccountHolderName(e.target.value)}
                  placeholder="Full Legal Name on Bank Account"
                  className="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xs font-semibold focus:border-indigo-600 focus:outline-none"
                />
              </div>

              {withdrawMethod === 'Bank' ? (
                <>
                  <div className="grid grid-cols-2 gap-2.5">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                        Bank Name *
                      </label>
                      <input
                        type="text"
                        value={bankName}
                        onChange={(e) => setBankName(e.target.value)}
                        placeholder="e.g. HDFC Bank"
                        className="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xs font-semibold focus:border-indigo-600 focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                        IFSC Code *
                      </label>
                      <input
                        type="text"
                        value={ifscCode}
                        onChange={(e) => setIfscCode(e.target.value)}
                        placeholder="e.g. HDFC0001234"
                        className="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xs font-semibold focus:border-indigo-600 focus:outline-none uppercase"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                      Account Number *
                    </label>
                    <input
                      type="text"
                      value={accountNumber}
                      onChange={(e) => setAccountNumber(e.target.value)}
                      placeholder="Bank Account Number"
                      className="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xs font-semibold focus:border-indigo-600 focus:outline-none"
                    />
                  </div>
                </>
              ) : (
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                    UPI VPA ID *
                  </label>
                  <input
                    type="text"
                    value={upiId}
                    onChange={(e) => setUpiId(e.target.value)}
                    placeholder="e.g. username@upi or mobile@paytm"
                    className="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xs font-semibold focus:border-indigo-600 focus:outline-none"
                  />
                </div>
              )}
            </div>

            {/* Security Badge Indicator */}
            <div className="flex items-center gap-2 p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700/80 text-xs text-slate-600 dark:text-slate-300">
              <ShieldCheck className="w-4 h-4 text-emerald-600 shrink-0" />
              <span>Requires Security PIN or Biometrics before payout execution.</span>
            </div>
          </div>

          {/* Modal Sticky Bottom Slider */}
          <div className="sticky bottom-0 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md p-4 border-t border-slate-100 dark:border-slate-800 rounded-b-3xl">
            <SlideToConfirm
              label="Slide To Confirm Withdrawal"
              onConfirm={handleSlideConfirmInitiate}
              disabled={!isFormValid}
              isLoading={isSubmitting}
              resetSignal={resetSliderSignal}
            />
          </div>
        </div>
      </div>

      {/* Security PIN Authorization Modal */}
      <SecurityVerificationModal
        isOpen={isSecurityModalOpen}
        onClose={() => {
          setIsSecurityModalOpen(false);
          setResetSliderSignal((prev) => prev + 1);
        }}
        onVerified={handleSecurityVerified}
        amount={amount}
        actionTitle="Authorize Payout Transfer"
      />
    </>
  );
};

export default WithdrawalModal;
