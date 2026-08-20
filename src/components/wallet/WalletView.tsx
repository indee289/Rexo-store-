import { motion, AnimatePresence } from 'framer-motion';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import React, {  useState , useEffect } from 'react';
import {
  Bell,
  ArrowUpRight,
  ArrowDownLeft,
  X,
  Sparkles,
  Receipt,
  ChevronRight,
} from 'lucide-react';
import { useStore } from '../../context/StoreContext';
import { WalletTransaction } from '../../types';
import { WalletCard } from './WalletCard';
import { WalletStats } from './WalletStats';
import { DepositView } from './DepositView';
import { WithdrawalView } from './WithdrawalView';
import { TransactionDetailsModal } from './TransactionDetailsModal';
import { PageHeader } from '../ui/PageHeader';

export const WalletView: React.FC<{
  onNavigateNotifications?: () => void;
}> = ({ onNavigateNotifications }) => {
  const {
    state,
    currentUser,
    unreadNotificationsCount,
  } = useStore();

  // Navigation sub-page state ('main' | 'deposit' | 'withdraw')
  const [activeSubPage, setActiveSubPage] = useState<'main' | 'deposit' | 'withdraw'>('main');

  const [selectedTxForDetails, setSelectedTxForDetails] = useState<WalletTransaction | null>(null);

  // Filter state
  const [txFilter, setTxFilter] = useState<'all' | 'deposit' | 'withdrawal' | 'escrow'>('all');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => setIsLoading(false), 800);
    return () => clearTimeout(timer);
  }, []);

  const handleFilterSwitch = (f) => {
    setIsLoading(true);
    setTxFilter(f);
    setTimeout(() => setIsLoading(false), 500);
  };

  const [showAllFilterPills, setShowAllFilterPills] = useState(false);

  // Toast feedback
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  };

  // Real Recent Transactions for Current User
  const userTransactions = state.transactions.filter(
    (t) => t.userId === currentUser.id
  );

  
  // Mock Data for Chart
  const chartData = [
    { name: 'Mon', earnings: 4000, spending: 2400 },
    { name: 'Tue', earnings: 3000, spending: 1398 },
    { name: 'Wed', earnings: 2000, spending: 9800 },
    { name: 'Thu', earnings: 2780, spending: 3908 },
    { name: 'Fri', earnings: 1890, spending: 4800 },
    { name: 'Sat', earnings: 2390, spending: 3800 },
    { name: 'Sun', earnings: 3490, spending: 4300 },
  ];

  const filteredTransactions = userTransactions.filter((t) => {
    if (txFilter === 'all') return true;
    if (txFilter === 'deposit') return t.type === 'deposit';
    if (txFilter === 'withdrawal') return t.type === 'withdrawal';
    if (txFilter === 'escrow')
      return (
        t.type === 'escrow_release' ||
        t.type === 'escrow_hold' ||
        t.type === 'campaign_payout'
      );
    return true;
  });

  // SUB-PAGES (FULL PAGE VIEWS AS REQUESTED)
  if (activeSubPage === 'deposit') {
    return (
      <DepositView
        onBack={() => setActiveSubPage('main')}
        onSuccess={(msg) => {
          showToast(msg);
          setActiveSubPage('main');
        }}
      />
    );
  }

  if (activeSubPage === 'withdraw') {
    return (
      <WithdrawalView
        onBack={() => setActiveSubPage('main')}
        onSuccess={(msg) => {
          showToast(msg);
          setActiveSubPage('main');
        }}
      />
    );
  }

  return (
    <div className="min-h-screen bg-[#F4F6F9] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans">
      <div className="max-w-md mx-auto px-4 space-y-5">
        
        {/* TOAST FEEDBACK OVERLAY */}
        {toastMessage && (
          <div className="fixed top-4 left-1/2 -translate-x-1/2 z-50 w-full max-w-xs px-3 animate-in fade-in slide-in-from-top duration-300">
            <div className="bg-slate-900 text-white dark:bg-white dark:text-slate-900 p-3 rounded-2xl shadow-2xl border border-slate-700 flex items-center justify-between gap-2 text-xs font-bold">
              <span className="flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-purple-400 shrink-0" />
                <span>{toastMessage}</span>
              </span>
              <button onClick={() => setToastMessage(null)}>
                <X className="w-4 h-4 text-slate-400 hover:text-white" />
              </button>
            </div>
          </div>
        )}

        {/* CLEAN TOP HEADER (NO MENU BUTTON, NO PLUS BUTTON, NO SUBTITLE) */}
        <PageHeader 
          title="Wallet"
          actions={
            onNavigateNotifications && (
              <button
                onClick={onNavigateNotifications}
                className="w-10 h-10 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 relative flex items-center justify-center shadow-2xs hover:bg-slate-50 active:scale-95 transition-all"
                title="Notifications"
              >
                <Bell size={18} />
                {unreadNotificationsCount > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full ring-2 ring-white dark:ring-slate-900" />
                )}
              </button>
            )
          }
        />

        {/* SLEEK WALLET CARD HERO */}
        <WalletCard
          onOpenDeposit={() => setActiveSubPage('deposit')}
          onOpenWithdraw={() => setActiveSubPage('withdraw')}
        />

        {/* WALLET SUMMARY STATS */}
        <WalletStats />

        
        {/* EARNINGS OVERVIEW CHART */}
        <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">Activity Overview</h3>
            <select className="bg-[#EBF0F5] dark:bg-slate-800 text-slate-700 dark:text-slate-300 text-xs font-bold px-2 py-1 rounded-lg border-none focus:ring-0">
              <option>This Week</option>
              <option>Last Week</option>
            </select>
          </div>
          <div className="h-40 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData} margin={{ top: 5, right: 0, left: -25, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorEarnings" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#94a3b8' }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#94a3b8' }} />
                <Tooltip 
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', fontSize: '12px', fontWeight: 'bold' }}
                />
                <Area type="monotone" dataKey="earnings" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorEarnings)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>


        {/* RECENT TRANSACTIONS */}
        <div id="recent-transactions-section" className="space-y-3 pt-2">
          {/* Section Header */}
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              Recent Transactions
            </h3>
            <button
              onClick={() => setShowAllFilterPills(!showAllFilterPills)}
              className="text-xs font-bold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 flex items-center gap-0.5"
            >
              See all <ChevronRight size={14} />
            </button>
          </div>

          {/* Optional Filter Pills */}
          {showAllFilterPills && (
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar scrollbar-none text-xs font-bold animate-fade-in">
              {(['all', 'deposit', 'withdrawal', 'escrow'] as const).map((filterKey) => (
                <button
                  key={filterKey}
                  onClick={() => handleFilterSwitch(filterKey)}
                  className={`${txFilter === filterKey ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all' : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 border border-transparent hover:bg-slate-200/80 px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all'}`}
                >
                  {filterKey}
                </button>
              ))}
            </div>
          )}

          {/* Transactions List Cards */}
          {filteredTransactions.length === 0 ? (
            <div className="p-8 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 space-y-2 shadow-2xs">
              <Receipt className="w-10 h-10 text-slate-300 dark:text-slate-700 mx-auto" />
              <h4 className="text-xs font-extrabold text-slate-800 dark:text-slate-200">
                No transactions yet
              </h4>
              <p className="text-[11px] text-slate-400 max-w-xs mx-auto">
                Your wallet activity will appear here.
              </p>
            </div>
          ) : (
            <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800/80 shadow-2xs">
              <AnimatePresence mode="popLayout">
              {filteredTransactions.map((tx) => {

                const isCredit = tx.direction === 'credit';
                return (
                  <motion.div
                    layout
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.9 }}
                    transition={{ duration: 0.2 }}

                    key={tx.id}
                    onClick={() => setSelectedTxForDetails(tx)}
                    className="p-3.5 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-all cursor-pointer group"
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 transition-transform group-hover:scale-105 ${
                          isCredit
                            ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950/60 dark:text-emerald-400'
                            : 'bg-rose-50 text-rose-600 dark:bg-rose-950/60 dark:text-rose-400'
                        }`}
                      >
                        {isCredit ? <ArrowDownLeft size={18} /> : <ArrowUpRight size={18} />}
                      </div>

                      <div>
                        <div className="font-extrabold text-slate-900 dark:text-white text-xs leading-snug">
                          {tx.note || (isCredit ? 'Deposit / Payout' : 'Withdrawal')}
                        </div>
                        <div className="text-[10px] text-slate-400 font-medium">
                          {new Date(tx.createdAt).toLocaleDateString('en-GB', {
                            day: 'numeric',
                            month: 'short',
                            year: 'numeric',
                          })}
                        </div>
                      </div>
                    </div>

                    <div className="text-right">
                      <div
                        className={`text-xs font-bold ${
                          isCredit
                            ? 'text-emerald-600 dark:text-emerald-400'
                            : 'text-rose-600 dark:text-rose-400'
                        }`}
                      >
                        {isCredit ? '+' : '-'}₹{tx.amount.toLocaleString('en-IN')}
                      </div>
                      <span className="text-[9px] font-bold text-slate-400 uppercase tracking-wider block">
                        {tx.status}
                      </span>
                    </div>
                  </motion.div>
                );
              })}
              </AnimatePresence>
            </div>
          )}
        </div>

      </div>

      {/* TRANSACTION DETAILS MODAL */}
      {selectedTxForDetails && (
        <TransactionDetailsModal
          transaction={selectedTxForDetails}
          onClose={() => setSelectedTxForDetails(null)}
        />
      )}
    </div>
  );
};

export default WalletView;
