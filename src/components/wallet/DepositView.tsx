import React, { useState } from 'react';
import {
  ArrowLeft,
  Building,
  QrCode,
  Copy,
  Check,
  AlertCircle,
  Sparkles,
  Upload,
  FileText,
} from 'lucide-react';
import { SlideToConfirm } from './SlideToConfirm';
import { useStore } from '../../context/StoreContext';

interface DepositViewProps {
  onBack: () => void;
  onSuccess: (msg: string) => void;
}

export const DepositView: React.FC<DepositViewProps> = ({ onBack, onSuccess }) => {
  const { depositBrandFunds } = useStore();

  const [amount, setAmount] = useState<number>(25000);
  const [paymentMethod, setPaymentMethod] = useState<'UPI' | 'Bank Transfer' | 'Manual Deposit'>('UPI');
  const [transactionRef, setTransactionRef] = useState<string>('UTR' + Math.floor(100000000 + Math.random() * 900000000));
  const [screenshotUrl, setScreenshotUrl] = useState<string>(
    'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400&auto=format&fit=crop&q=80'
  );
  const [notes, setNotes] = useState<string>('');
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [resetSliderSignal, setResetSliderSignal] = useState(0);

  const copyToClipboard = (text: string, fieldName: string) => {
    navigator.clipboard.writeText(text);
    setCopiedField(fieldName);
    setTimeout(() => setCopiedField(null), 2000);
  };

  const handleSlideConfirm = () => {
    if (amount <= 0 || !transactionRef.trim()) {
      setResetSliderSignal((prev) => prev + 1);
      return;
    }

    setIsSubmitting(true);

    setTimeout(() => {
      const res = depositBrandFunds(amount, paymentMethod, transactionRef, screenshotUrl, notes);
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

  const presetAmounts = [5000, 10000, 25000, 50000, 100000];

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
              Deposit Funds to Escrow
            </h1>
            <p className="text-[11px] font-medium text-slate-400">
              Fund your Brand Escrow Wallet via UPI or Bank
            </p>
          </div>
        </div>

        {/* DEPOSIT AMOUNT FIELD */}
        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200/80 dark:border-slate-800 space-y-3 shadow-2xs">
          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider">
            Deposit Amount (INR ₹)
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

          {/* Quick Preset Amount Pills */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar scrollbar-none">
            {presetAmounts.map((preset) => (
              <button
                key={preset}
                type="button"
                onClick={() => setAmount(preset)}
                className={`px-3 py-1 rounded-xl text-xs font-bold transition-all shrink-0 ${
                  amount === preset
                    ? 'bg-indigo-600 text-white'
                    : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-200'
                }`}
              >
                +₹{preset.toLocaleString('en-IN')}
              </button>
            ))}
          </div>
        </div>

        {/* PAYMENT METHOD SELECTOR */}
        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200/80 dark:border-slate-800 space-y-2.5 shadow-2xs">
          <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider">
            Payment Method
          </label>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => setPaymentMethod('UPI')}
              className={`p-3 rounded-xl border text-xs font-bold transition-all text-left flex items-center gap-2 ${
                paymentMethod === 'UPI'
                  ? 'border-indigo-600 bg-indigo-50/80 text-indigo-900 dark:bg-indigo-950/50 dark:text-indigo-200'
                  : 'border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
              }`}
            >
              <QrCode size={16} className="text-indigo-600" />
              <span>Instant UPI QR</span>
            </button>

            <button
              type="button"
              onClick={() => setPaymentMethod('Bank Transfer')}
              className={`p-3 rounded-xl border text-xs font-bold transition-all text-left flex items-center gap-2 ${
                paymentMethod === 'Bank Transfer'
                  ? 'border-indigo-600 bg-indigo-50/80 text-indigo-900 dark:bg-indigo-950/50 dark:text-indigo-200'
                  : 'border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400'
              }`}
            >
              <Building size={16} className="text-indigo-600" />
              <span>Bank NEFT / RTGS</span>
            </button>
          </div>

          {/* PAYMENT DETAILS CARD */}
          <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl border border-slate-200 dark:border-slate-700/80 text-xs space-y-2">
            {paymentMethod === 'UPI' ? (
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-[10px] text-slate-400 font-bold block">OFFICIAL VPA</span>
                  <span className="font-extrabold text-slate-900 dark:text-white">rexomarket@icici</span>
                </div>
                <button
                  type="button"
                  onClick={() => copyToClipboard('rexomarket@icici', 'vpa')}
                  className="px-2.5 py-1 bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-lg font-bold text-[10px] flex items-center gap-1"
                >
                  {copiedField === 'vpa' ? <Check size={12} className="text-emerald-500" /> : <Copy size={12} />}
                  <span>{copiedField === 'vpa' ? 'Copied' : 'Copy'}</span>
                </button>
              </div>
            ) : (
              <div className="space-y-1.5 text-slate-700 dark:text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-400 font-bold">Bank:</span>
                  <span className="font-bold text-slate-900 dark:text-white">ICICI Bank Ltd</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400 font-bold">A/C Name:</span>
                  <span className="font-bold text-slate-900 dark:text-white">Rexo Market Escrow</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400 font-bold">A/C Number:</span>
                  <span className="font-mono font-bold text-slate-900 dark:text-white">000405012389</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400 font-bold">IFSC:</span>
                  <span className="font-mono font-bold text-slate-900 dark:text-white">ICIC0000004</span>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* UTR TRANSACTION REF INPUT */}
        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200/80 dark:border-slate-800 space-y-3 shadow-2xs">
          <div>
            <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
              UTR / Bank Transaction Ref *
            </label>
            <input
              type="text"
              value={transactionRef}
              onChange={(e) => setTransactionRef(e.target.value)}
              placeholder="e.g. UTR123456789"
              className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs font-bold text-slate-900 dark:text-white uppercase"
            />
          </div>

          <div>
            <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
              Optional Note
            </label>
            <input
              type="text"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add payment reference note"
              className="w-full bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs font-bold text-slate-900 dark:text-white"
            />
          </div>
        </div>

        {/* SLIDE TO CONFIRM */}
        <div className="pt-2">
          <SlideToConfirm
            onConfirm={handleSlideConfirm}
            disabled={amount <= 0 || !transactionRef.trim() || isSubmitting}
            resetSignal={resetSliderSignal}
            text={
              amount <= 0 || !transactionRef.trim()
                ? 'ENTER DEPOSIT DETAILS ABOVE'
                : isSubmitting
                ? 'PROCESSING DEPOSIT...'
                : 'SLIDE TO CONFIRM DEPOSIT'
            }
          />
        </div>

      </div>
    </div>
  );
};

export default DepositView;
