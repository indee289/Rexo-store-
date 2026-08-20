import React, { useState } from 'react';
import { Plus, Repeat, Eye, EyeOff } from 'lucide-react';
import { useStore } from '../../context/StoreContext';

interface WalletCardProps {
  onOpenDeposit: () => void;
  onOpenWithdraw: () => void;
}

export const WalletCard: React.FC<WalletCardProps> = ({
  onOpenDeposit,
  onOpenWithdraw,
}) => {
  const { currentWallet } = useStore();
  const availableBalance = currentWallet.availableBalance ?? 0;
  const [showBalance, setShowBalance] = useState(false);

  return (
    <div className="w-full bg-white dark:bg-slate-900 rounded-3xl p-6 border border-slate-100 dark:border-slate-800 shadow-sm flex flex-col items-center">
      <div 
        className="flex flex-col items-center text-center cursor-pointer mb-6"
        onClick={() => setShowBalance(!showBalance)}
      >
        <span className="text-xs font-black text-slate-400 uppercase tracking-wider mb-2 flex items-center gap-1.5">
          Available Balance
          {showBalance ? <EyeOff size={14} /> : <Eye size={14} />}
        </span>
        <div className="text-4xl font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-1">
          <span className="text-xl text-slate-400 dark:text-slate-500 font-medium">₹</span>
          {showBalance ? availableBalance.toLocaleString() : '****'}
        </div>
        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mt-2 bg-slate-100 dark:bg-slate-800 px-2.5 py-1 rounded-full">
          Tap to see balance
        </p>
      </div>

      <div className="flex w-full gap-3">
        <button
          onClick={onOpenDeposit}
          className="flex-1 bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-bold text-sm py-3.5 rounded-xl shadow-xs transition-all active:scale-95 flex items-center justify-center gap-2"
        >
          <Plus size={16} /> Deposit
        </button>
        <button
          onClick={onOpenWithdraw}
          className="flex-1 bg-[#EBF0F5] dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold text-sm py-3.5 rounded-xl shadow-xs transition-all hover:bg-slate-200 dark:hover:bg-slate-700 active:scale-95 flex items-center justify-center gap-2"
        >
          <Repeat size={16} /> Withdraw
        </button>
      </div>
    </div>
  );
};

export default WalletCard;
