import React, { useState } from 'react';
import { ShieldCheck, Lock, Fingerprint, KeyRound, AlertCircle, X, CheckCircle2 } from 'lucide-react';

interface SecurityVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onVerified: () => void;
  amount: number;
  actionTitle?: string;
}

export const SecurityVerificationModal: React.FC<SecurityVerificationModalProps> = ({
  isOpen,
  onClose,
  onVerified,
  amount,
  actionTitle = 'Withdrawal Authorization',
}) => {
  const [pin, setPin] = useState<string[]>(['', '', '', '']);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isBiometricAuthenticating, setIsBiometricAuthenticating] = useState(false);

  if (!isOpen) return null;

  const handleDigitClick = (num: string) => {
    setErrorMsg(null);
    const emptyIndex = pin.findIndex((val) => val === '');
    if (emptyIndex !== -1) {
      const newPin = [...pin];
      newPin[emptyIndex] = num;
      setPin(newPin);

      // Auto submit if 4 digits entered
      if (emptyIndex === 3) {
        verifyPin(newPin.join(''));
      }
    }
  };

  const handleBackspace = () => {
    setErrorMsg(null);
    const lastFilledIndex = pin.map((val) => val !== '').lastIndexOf(true);
    if (lastFilledIndex !== -1) {
      const newPin = [...pin];
      newPin[lastFilledIndex] = '';
      setPin(newPin);
    }
  };

  const verifyPin = (pinString: string) => {
    // Default master demo PIN: 1234 or any 4 digits
    if (pinString.length === 4) {
      setTimeout(() => {
        onVerified();
        setPin(['', '', '', '']);
      }, 300);
    } else {
      setErrorMsg('Invalid Security PIN. Try 1234');
    }
  };

  const handleBiometricAuth = () => {
    setIsBiometricAuthenticating(true);
    setErrorMsg(null);
    setTimeout(() => {
      setIsBiometricAuthenticating(false);
      onVerified();
    }, 1200);
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/80 backdrop-blur-md flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in duration-200">
      <div className="w-full max-w-md bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-t-3xl sm:rounded-3xl p-4 shadow-2xl space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-3">
          <div className="flex items-center gap-2.5">
            <div className="p-2.5 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white leading-tight">
                {actionTitle}
              </h3>
              <p className="text-xs text-slate-500">Security PIN or Biometric Required</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Amount Confirmation Pill */}
        <div className="bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/80 rounded-2xl p-4 text-center">
          <span className="text-xs text-slate-500 dark:text-slate-400 uppercase font-bold tracking-wider">
            Authorizing Transfer
          </span>
          <div className="text-2xl font-black text-slate-900 dark:text-white mt-0.5">
            ₹{amount.toLocaleString('en-IN')}
          </div>
        </div>

        {/* PIN Inputs */}
        <div className="space-y-2">
          <div className="flex justify-center items-center gap-3">
            {pin.map((digit, idx) => (
              <div
                key={idx}
                className={`w-12 h-12 rounded-xl border-2 flex items-center justify-center text-xl font-black transition-all ${
                  digit
                    ? 'border-indigo-600 bg-indigo-50/50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 shadow-sm'
                    : 'border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-400'
                }`}
              >
                {digit ? '•' : ''}
              </div>
            ))}
          </div>

          {errorMsg && (
            <p className="text-xs text-rose-500 text-center font-semibold flex items-center justify-center gap-1">
              <AlertCircle className="w-3.5 h-3.5" />
              {errorMsg}
            </p>
          )}
        </div>

        {/* Keypad */}
        <div className="grid grid-cols-3 gap-2 max-w-xs mx-auto pt-2">
          {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => (
            <button
              key={num}
              onClick={() => handleDigitClick(num)}
              className="h-12 rounded-2xl bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-900 dark:text-white font-bold text-lg active:scale-95 transition-all"
            >
              {num}
            </button>
          ))}
          <button
            onClick={handleBiometricAuth}
            className="h-12 rounded-2xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center active:scale-95 transition-all"
            title="Biometric Fingerprint"
          >
            <Fingerprint className="w-6 h-6" />
          </button>
          <button
            onClick={() => handleDigitClick('0')}
            className="h-12 rounded-2xl bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-900 dark:text-white font-bold text-lg active:scale-95 transition-all"
          >
            0
          </button>
          <button
            onClick={handleBackspace}
            className="h-12 rounded-2xl bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 font-bold text-xs active:scale-95 transition-all flex items-center justify-center"
          >
            Delete
          </button>
        </div>

        {/* Biometric quick trigger */}
        <button
          onClick={handleBiometricAuth}
          disabled={isBiometricAuthenticating}
          className="w-full py-3 rounded-2xl border border-indigo-200 dark:border-indigo-800/80 bg-indigo-50/50 dark:bg-indigo-950/30 hover:bg-indigo-100 dark:hover:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 text-xs font-bold flex items-center justify-center gap-2 transition-all"
        >
          <Fingerprint className="w-4 h-4" />
          {isBiometricAuthenticating ? 'Scanning Biometrics...' : 'Use Face ID / Fingerprint Sensor'}
        </button>
      </div>
    </div>
  );
};
