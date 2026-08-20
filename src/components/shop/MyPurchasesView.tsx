import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { StoreOrder } from '../../types';
import {
  ArrowLeft,
  PackageCheck,
  Download,
  ExternalLink,
  Key,
  Truck,
  CheckCircle2,
  Clock,
  Copy,
  Check,
  X,
  FileText,
  Sparkles,
} from 'lucide-react';

interface MyPurchasesViewProps {
  onBack: () => void;
}

export const MyPurchasesView: React.FC<MyPurchasesViewProps> = ({ onBack }) => {
  const { state, currentUser } = useStore();

  const orders = (state.orders || []).filter((o) => o.userId === currentUser.id);

  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const handleCopyKey = (keyStr: string) => {
    navigator.clipboard.writeText(keyStr);
    setCopiedKey(keyStr);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans transition-colors">
      <div className="max-w-2xl mx-auto px-4 space-y-5">
        {/* HEADER */}
        <div className="flex items-center gap-3 pt-1">
          <button
            onClick={onBack}
            className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 shadow-2xs hover:bg-slate-50 transition-all active:scale-95"
          >
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">
              My Purchases & Downloads
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
              Access your unlocked digital files, licenses & physical shipment updates
            </p>
          </div>
        </div>

        {/* PURCHASES LIST */}
        {orders.length === 0 ? (
          <div className="p-10 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 space-y-3 mt-6">
            <PackageCheck className="w-12 h-12 text-slate-300 dark:text-slate-700 mx-auto" />
            <h3 className="text-base font-extrabold text-slate-800 dark:text-white">
              No Purchases Yet
            </h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm mx-auto">
              You haven't bought any digital bundles, merchandise or growth packages yet. Explore the Rexo Store catalog to unlock premium resources!
            </p>
            <button
              onClick={onBack}
              className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl text-xs font-extrabold transition-all active:scale-95 shadow-xs"
            >
              Browse Rexo Store
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            {orders.map((order) => {
              const isDigital =
                order.productType === 'digital_product' || order.productType === 'free_resource';

              return (
                <div
                  key={order.id}
                  className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 p-5 shadow-2xs space-y-4"
                >
                  {/* ORDER HEADER */}
                  <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800/80 pb-3">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-black text-slate-900 dark:text-white">
                          Order #{order.id.slice(-8).toUpperCase()}
                        </span>
                        <span className="text-[10px] text-slate-400">
                          • {new Date(order.createdAt).toLocaleDateString('en-IN')}
                        </span>
                      </div>
                      <span className="text-[11px] text-slate-500 font-medium block">
                        Transaction Ref: {order.transactionRef}
                      </span>
                    </div>

                    {/* Status Badge */}
                    <div>
                      {order.status === 'unlocked' || order.status === 'delivered' ? (
                        <span className="px-3 py-1 bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300 text-[10px] font-black rounded-full flex items-center gap-1">
                          <CheckCircle2 size={12} /> {order.status.toUpperCase()}
                        </span>
                      ) : (
                        <span className="px-3 py-1 bg-amber-100 dark:bg-amber-950 text-amber-700 dark:text-amber-300 text-[10px] font-black rounded-full flex items-center gap-1">
                          <Clock size={12} /> {order.status.toUpperCase()}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* ORDER ITEMS */}
                  <div className="space-y-3">
                    {order.items.map((item, idx) => (
                      <div key={idx} className="flex items-start gap-3">
                        <img
                          src={item.coverImage}
                          alt={item.productTitle}
                          className="w-16 h-16 rounded-2xl object-cover shrink-0 border border-slate-200/80 dark:border-slate-700"
                        />
                        <div className="flex-1 min-w-0 space-y-1">
                          <h4 className="text-xs font-extrabold text-slate-900 dark:text-white leading-tight">
                            {item.productTitle}
                          </h4>

                          <div className="text-[11px] font-black text-indigo-600 dark:text-indigo-400">
                            ₹{item.price} x {item.quantity}
                          </div>

                          {/* DIGITAL UNLOCKED DOWNLOAD ACTION BUTTONS */}
                          {isDigital && (
                            <div className="pt-2 flex flex-wrap items-center gap-2">
                              {item.downloadUrl && (
                                <a
                                  href={item.downloadUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-xs transition-all"
                                >
                                  <Download size={13} /> Download File
                                </a>
                              )}

                              {item.driveUrl && (
                                <a
                                  href={item.driveUrl}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
                                >
                                  <ExternalLink size={13} /> Open Google Drive
                                </a>
                              )}

                              {item.licenseKey && (
                                <button
                                  onClick={() => handleCopyKey(item.licenseKey!)}
                                  className="px-3 py-1.5 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 rounded-xl text-xs font-bold flex items-center gap-1.5 hover:bg-slate-200 transition-all"
                                >
                                  <Key size={13} />
                                  <span>
                                    {copiedKey === item.licenseKey ? 'Key Copied!' : `License: ${item.licenseKey}`}
                                  </span>
                                </button>
                              )}
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* SHIPPING ADDRESS SUMMARY FOR PHYSICAL ORDERS */}
                  {order.shippingAddress && (
                    <div className="p-3.5 bg-slate-50 dark:bg-slate-800/60 rounded-2xl text-xs space-y-1 border border-slate-200/70 dark:border-slate-700/70">
                      <div className="font-extrabold text-slate-900 dark:text-white flex items-center gap-1.5">
                        <Truck size={14} className="text-indigo-600" /> Delivery Address
                      </div>
                      <p className="text-slate-600 dark:text-slate-300 font-medium">
                        {order.shippingAddress.fullName} ({order.shippingAddress.mobile})
                      </p>
                      <p className="text-slate-500 dark:text-slate-400 font-medium">
                        {order.shippingAddress.address}, {order.shippingAddress.city},{' '}
                        {order.shippingAddress.state} - {order.shippingAddress.pincode}
                      </p>
                    </div>
                  )}

                  {/* TOTAL SUMMARY */}
                  <div className="flex items-center justify-between text-xs font-black pt-1">
                    <span className="text-slate-400">Total Paid</span>
                    <span className="text-base text-slate-900 dark:text-white">
                      ₹{order.totalAmount}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
