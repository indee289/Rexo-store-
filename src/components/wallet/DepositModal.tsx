import React, { useState } from 'react';
import {
  X,
  Building,
  QrCode,
  Upload,
  Copy,
  Check,
  CreditCard,
  FileText,
  Sparkles,
  AlertCircle,
  HelpCircle,
  Image as ImageIcon,
  ArrowRight,
} from 'lucide-react';
import { SlideToConfirm } from './SlideToConfirm';
import { useStore } from '../../context/StoreContext';

interface DepositModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (msg: string) => void;
}

export const DepositModal: React.FC<DepositModalProps> = ({ isOpen, onClose, onSuccess }) => {
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

  if (!isOpen) return null;

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
        onClose();
      } else {
        alert(res.message);
        setResetSliderSignal((prev) => prev + 1);
      }
    }, 600);
  };

  const presetAmounts = [5000, 10000, 25000, 50000, 100000];

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/80 backdrop-blur-md flex items-end sm:items-center justify-center p-0 sm:p-4 overflow-y-auto animate-in fade-in duration-200">
      <div className="w-full max-w-lg bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-t-3xl sm:rounded-3xl shadow-2xl flex flex-col max-h-[92vh]">
        {/* Modal Header */}
        <div className="sticky top-0 z-20 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between rounded-t-3xl">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-gradient-to-tr from-indigo-600 to-purple-600 text-white shadow-md">
              <Building className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900 dark:text-white leading-tight">
                Deposit Funds to Escrow
              </h2>
              <p className="text-xs text-slate-500">Fund your Brand Escrow Wallet via UPI or Bank Transfer</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Scrollable Body */}
        <div className="p-6 overflow-y-auto space-y-5 flex-1">
          {/* Deposit Amount Field */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
              Deposit Amount (INR ₹)
            </label>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-2xl font-black text-indigo-600">
                ₹
              </span>
              <input
                type="number"
                value={amount || ''}
                onChange={(e) => setAmount(Number(e.target.value))}
                placeholder="Enter deposit amount"
                className="w-full pl-10 pr-4 py-3.5 rounded-2xl border-2 border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xl font-bold focus:border-indigo-600 focus:outline-none transition-all"
              />
            </div>

            {/* Quick Presets */}
            <div className="flex items-center gap-2 overflow-x-auto no-scrollbar mt-2.5">
              {presetAmounts.map((preset) => (
                <button
                  key={preset}
                  type="button"
                  onClick={() => setAmount(preset)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                    amount === preset
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
                  }`}
                >
                  +₹{preset.toLocaleString('en-IN')}
                </button>
              ))}
            </div>
          </div>

          {/* Payment Method Options */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
              Select Payment Method
            </label>
            <div className="grid grid-cols-3 gap-2">
              {[
                { id: 'UPI', label: 'UPI / VPA', icon: QrCode },
                { id: 'Bank Transfer', label: 'Bank Transfer', icon: Building },
                { id: 'Manual Deposit', label: 'Manual Wire', icon: FileText },
              ].map((method) => {
                const Icon = method.icon;
                const isSelected = paymentMethod === method.id;
                return (
                  <button
                    key={method.id}
                    type="button"
                    onClick={() => setPaymentMethod(method.id as any)}
                    className={`p-3 rounded-2xl border-2 text-left transition-all flex flex-col items-start gap-2 ${
                      isSelected
                        ? 'border-indigo-600 bg-indigo-50/50 dark:bg-indigo-950/40 text-indigo-900 dark:text-indigo-200 shadow-sm'
                        : 'border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-800/50 text-slate-600 dark:text-slate-400 hover:border-slate-300 dark:hover:border-slate-700'
                    }`}
                  >
                    <Icon className={`w-5 h-5 ${isSelected ? 'text-indigo-600' : 'text-slate-400'}`} />
                    <span className="text-xs font-bold leading-tight">{method.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Transfer Instruction Details Box */}
          <div className="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/70 border border-slate-200 dark:border-slate-700 space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                <Sparkles className="w-4 h-4 text-indigo-600" />
                {paymentMethod === 'UPI' ? 'Scan & Pay via VPA VPA' : 'Official REXO Escrow Account'}
              </span>
              <span className="text-[10px] px-2 py-0.5 rounded-full font-bold bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300">
                Instant Verification
              </span>
            </div>

            {paymentMethod === 'UPI' ? (
              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700">
                  <div>
                    <span className="text-[10px] text-slate-400 block">UPI VPA ID</span>
                    <span className="font-mono font-bold text-slate-900 dark:text-white">rexo.escrow@icici</span>
                  </div>
                  <button
                    onClick={() => copyToClipboard('rexo.escrow@icici', 'vpa')}
                    className="p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-indigo-600 font-semibold text-xs flex items-center gap-1 hover:bg-indigo-50"
                  >
                    {copiedField === 'vpa' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                    {copiedField === 'vpa' ? 'Copied' : 'Copy'}
                  </button>
                </div>
              </div>
            ) : (
              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700">
                  <div>
                    <span className="text-[10px] text-slate-400 block">Bank Name</span>
                    <span className="font-bold text-slate-900 dark:text-white">ICICI Bank Corporate</span>
                  </div>
                </div>
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700">
                  <div>
                    <span className="text-[10px] text-slate-400 block">Account Number</span>
                    <span className="font-mono font-bold text-slate-900 dark:text-white">0004050129384</span>
                  </div>
                  <button
                    onClick={() => copyToClipboard('0004050129384', 'ac')}
                    className="p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-indigo-600 font-semibold text-xs flex items-center gap-1 hover:bg-indigo-50"
                  >
                    {copiedField === 'ac' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                    {copiedField === 'ac' ? 'Copied' : 'Copy'}
                  </button>
                </div>
                <div className="flex items-center justify-between p-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700">
                  <div>
                    <span className="text-[10px] text-slate-400 block">IFSC Code</span>
                    <span className="font-mono font-bold text-slate-900 dark:text-white">ICIC0000004</span>
                  </div>
                  <button
                    onClick={() => copyToClipboard('ICIC0000004', 'ifsc')}
                    className="p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-indigo-600 font-semibold text-xs flex items-center gap-1 hover:bg-indigo-50"
                  >
                    {copiedField === 'ifsc' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                    {copiedField === 'ifsc' ? 'Copied' : 'Copy'}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Reference Number / UTR ID */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
              Transaction Reference / UTR Number *
            </label>
            <input
              type="text"
              value={transactionRef}
              onChange={(e) => setTransactionRef(e.target.value)}
              placeholder="e.g. UTR9988221122 or Bank Ref No"
              className="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-sm font-semibold focus:border-indigo-600 focus:outline-none transition-all"
            />
          </div>

          {/* Payment Screenshot Upload */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
              Upload Payment Screenshot
            </label>
            {screenshotUrl ? (
              <div className="relative rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-700 bg-slate-100 dark:bg-slate-800 p-2 flex items-center gap-3">
                <img
                  src={screenshotUrl}
                  alt="Proof screenshot"
                  className="w-14 h-14 rounded-xl object-cover border"
                />
                <div className="flex-1">
                  <span className="text-xs font-bold text-slate-900 dark:text-white block">
                    Payment_Proof_Ref.png
                  </span>
                  <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-semibold flex items-center gap-1">
                    <Check className="w-3 h-3" /> Attached successfully
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setScreenshotUrl('')}
                  className="p-1.5 rounded-lg bg-rose-50 text-rose-600 dark:bg-rose-950 text-xs font-bold hover:bg-rose-100"
                >
                  Change
                </button>
              </div>
            ) : (
              <div
                onClick={() =>
                  setScreenshotUrl('https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400&auto=format&fit=crop&q=80')
                }
                className="border-2 border-dashed border-slate-300 dark:border-slate-700 rounded-2xl p-4 text-center cursor-pointer hover:border-indigo-600 transition-colors bg-slate-50 dark:bg-slate-800/50"
              >
                <Upload className="w-6 h-6 text-indigo-600 mx-auto mb-1" />
                <p className="text-xs font-bold text-slate-900 dark:text-white">
                  Click to select payment receipt / screenshot
                </p>
                <p className="text-[10px] text-slate-400 mt-0.5">Supports PNG, JPG, PDF up to 10MB</p>
              </div>
            )}
          </div>

          {/* Notes Optional */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
              Deposit Notes (Optional)
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add campaign name or budget notes for admin verification"
              rows={2}
              className="w-full px-4 py-2.5 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-slate-900 dark:text-white text-xs focus:border-indigo-600 focus:outline-none"
            />
          </div>
        </div>

        {/* Modal Sticky Bottom Slider Confirmation */}
        <div className="sticky bottom-0 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md p-4 border-t border-slate-100 dark:border-slate-800 rounded-b-3xl">
          <SlideToConfirm
            label="Slide To Confirm Deposit"
            onConfirm={handleSlideConfirm}
            disabled={amount <= 0 || !transactionRef.trim()}
            isLoading={isSubmitting}
            resetSignal={resetSliderSignal}
          />
        </div>
      </div>
    </div>
  );
};
