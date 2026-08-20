
import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle2, XCircle, Info, X } from 'lucide-react';
import { useToast } from '../../context/ToastContext';

export const GlobalToaster = () => {
  const { toasts, removeToast } = useToast();

  return (
    <div className="fixed top-4 right-4 z-[60] flex flex-col gap-2 pointer-events-none w-full max-w-sm px-4">
      <AnimatePresence mode="popLayout">
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            layout
            initial={{ opacity: 0, y: -20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9, x: 20 }}
            transition={{ type: 'spring', stiffness: 400, damping: 30 }}
            className={`pointer-events-auto flex items-start gap-3 p-4 rounded-2xl shadow-lg border backdrop-blur-md ${
              toast.type === 'success' ? 'bg-emerald-50/90 dark:bg-emerald-950/90 border-emerald-200/50 dark:border-emerald-800/50 text-emerald-900 dark:text-emerald-100' :
              toast.type === 'error' ? 'bg-rose-50/90 dark:bg-rose-950/90 border-rose-200/50 dark:border-rose-800/50 text-rose-900 dark:text-rose-100' :
              'bg-blue-50/90 dark:bg-blue-950/90 border-blue-200/50 dark:border-blue-800/50 text-blue-900 dark:text-blue-100'
            }`}
          >
            <div className="shrink-0 mt-0.5">
              {toast.type === 'success' && <CheckCircle2 size={18} className="text-emerald-500 dark:text-emerald-400" />}
              {toast.type === 'error' && <XCircle size={18} className="text-rose-500 dark:text-rose-400" />}
              {toast.type === 'info' && <Info size={18} className="text-blue-500 dark:text-blue-400" />}
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="text-sm font-bold">{toast.title}</h4>
              <p className="text-xs opacity-90 mt-0.5 leading-relaxed">{toast.message}</p>
            </div>
            <button 
              onClick={() => removeToast(toast.id)}
              className="shrink-0 p-1 rounded-full hover:bg-black/5 dark:hover:bg-white/10 transition-colors"
            >
              <X size={14} />
            </button>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
};
