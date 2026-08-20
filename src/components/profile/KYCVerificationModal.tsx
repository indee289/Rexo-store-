import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import {
  X,
  ShieldCheck,
  FileText,
  UploadCloud,
  CheckCircle2,
  AlertCircle,
  Clock,
  Lock,
  ChevronRight,
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface KYCVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const KYCVerificationModal: React.FC<KYCVerificationModalProps> = ({
  isOpen,
  onClose,
}) => {
  const { currentUser, currentKYC, submitKYCDocument } = useStore();
  const [docType, setDocType] = useState<'aadhaar' | 'pan' | 'passport' | 'gst'>('pan');
  const [docNumber, setDocNumber] = useState('');
  const [fileName, setFileName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [successNotice, setSuccessNotice] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!docNumber.trim()) return;
    setIsSubmitting(true);
    setTimeout(() => {
      submitKYCDocument(docType, docNumber.trim().toUpperCase());
      setIsSubmitting(false);
      setSuccessNotice(true);
      setTimeout(() => {
        setSuccessNotice(false);
        onClose();
      }, 1800);
    }, 600);
  };

  const getDocPlaceholder = () => {
    switch (docType) {
      case 'pan':
        return 'e.g. ABCDE1234F';
      case 'aadhaar':
        return 'e.g. 1234 5678 9012';
      case 'gst':
        return 'e.g. 29ABCDE1234F1Z5';
      case 'passport':
        return 'e.g. Z1234567';
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 10 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 10 }}
          className="bg-white w-full max-w-lg rounded-3xl p-4 shadow-2xl overflow-hidden border border-slate-100 max-h-[90vh] flex flex-col"
        >
          {/* Header */}
          <div className="flex items-center justify-between pb-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-indigo-50 flex items-center justify-center text-indigo-600">
                <ShieldCheck size={22} className="stroke-[2.2px]" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900">Identity & KYC Verification</h3>
                <p className="text-xs text-slate-500 font-medium">Compliance & Payout Security</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-slate-200 transition-colors"
            >
              <X size={16} />
            </button>
          </div>

          {/* Body */}
          <div className="overflow-y-auto py-4 space-y-5 pr-1">
            {/* Status Card */}
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100/80">
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-600">Current Status</span>
                  <div className="flex items-center gap-2 mt-1">
                    {currentKYC?.status === 'verified' ? (
                      <>
                        <CheckCircle2 size={18} className="text-emerald-700" />
                        <span className="text-sm font-bold text-emerald-800">KYC Verified Level 2</span>
                      </>
                    ) : currentKYC?.status === 'pending' ? (
                      <>
                        <Clock size={18} className="text-amber-700" />
                        <span className="text-sm font-bold text-amber-800">Under Review</span>
                      </>
                    ) : (
                      <>
                        <AlertCircle size={18} className="text-rose-700" />
                        <span className="text-sm font-bold text-rose-800">Unverified Account</span>
                      </>
                    )}
                  </div>
                </div>

                {currentKYC && (
                  <span className="text-xs px-2.5 py-1 rounded-lg bg-white border border-slate-200 font-medium text-slate-600 uppercase">
                    {currentKYC.documentType} • {currentKYC.documentNumber}
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-500 mt-2 font-medium">
                Verified creators and merchants receive instant automated UPI/Bank settlements and a verified green tick.
              </p>
            </div>

            {successNotice ? (
              <div className="p-6 text-center space-y-2 bg-emerald-50 rounded-2xl border border-emerald-100">
                <CheckCircle2 size={36} className="text-emerald-700 mx-auto" />
                <h4 className="text-sm font-bold text-emerald-950">Documents Received</h4>
                <p className="text-xs text-emerald-800">Your KYC submission is being verified with official registries.</p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                {/* Document Type Selector */}
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-2">Select Government ID Type</label>
                  <div className="grid grid-cols-2 gap-2">
                    {(['pan', 'aadhaar', 'gst', 'passport'] as const).map((type) => (
                      <button
                        key={type}
                        type="button"
                        onClick={() => setDocType(type)}
                        className={`p-3 rounded-2xl text-left border transition-all ${
                          docType === type
                            ? 'border-indigo-600 bg-indigo-50/50 text-indigo-900 font-bold'
                            : 'border-slate-200 bg-white text-slate-700 hover:border-slate-300'
                        }`}
                      >
                        <span className="text-xs uppercase tracking-wide">{type === 'pan' ? 'PAN Card' : type === 'aadhaar' ? 'Aadhaar Card' : type === 'gst' ? 'GSTIN Certificate' : 'Passport'}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* ID Number */}
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1.5">
                    {docType.toUpperCase()} Number
                  </label>
                  <input
                    type="text"
                    required
                    value={docNumber}
                    onChange={(e) => setDocNumber(e.target.value)}
                    placeholder={getDocPlaceholder()}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm font-medium text-slate-900 uppercase focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white transition-all"
                  />
                </div>

                {/* File Upload Simulation */}
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1.5">Upload Official Scan / PDF</label>
                  <div
                    onClick={() => setFileName(`${docType.toUpperCase()}_Document_Scan.pdf`)}
                    className="border-2 border-dashed border-slate-200 hover:border-indigo-400 bg-slate-50/60 rounded-2xl p-4 text-center cursor-pointer transition-colors"
                  >
                    <UploadCloud size={24} className="text-indigo-500 mx-auto mb-1.5" />
                    <p className="text-xs font-semibold text-slate-700">
                      {fileName ? fileName : 'Click to attach image or document'}
                    </p>
                    <p className="text-[11px] text-slate-500 mt-0.5 font-medium">JPEG, PNG or PDF up to 10MB</p>
                  </div>
                </div>

                <div className="flex items-center gap-2 p-3 rounded-xl bg-amber-50/70 border border-amber-100/80 text-amber-900 text-xs font-medium">
                  <Lock size={14} className="shrink-0 text-amber-700" />
                  <span>Your identity documents are encrypted with AES-256 and verified through UIDAI / NSDL API.</span>
                </div>

                <button
                  type="submit"
                  disabled={isSubmitting || !docNumber}
                  className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
                >
                  {isSubmitting ? (
                    <span>Verifying Document...</span>
                  ) : (
                    <>
                      <span>Submit for Instant Verification</span>
                      <ChevronRight size={16} />
                    </>
                  )}
                </button>
              </form>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
