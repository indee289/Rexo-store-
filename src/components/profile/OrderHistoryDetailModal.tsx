import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import {
  X,
  Package,
  Truck,
  CheckCircle2,
  Clock,
  Download,
  AlertCircle,
  FileText,
  RotateCcw,
  ExternalLink,
  MapPin,
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Order } from '../../types';

interface OrderHistoryDetailModalProps {
  order: Order | null;
  isOpen: boolean;
  onClose: () => void;
}

export const OrderHistoryDetailModal: React.FC<OrderHistoryDetailModalProps> = ({
  order,
  isOpen,
  onClose,
}) => {
  const { createReturnRequest } = useStore();
  const [isReturnModalOpen, setIsReturnModalOpen] = useState(false);
  const [returnReason, setReturnReason] = useState('');
  const [selectedProductId, setSelectedProductId] = useState('');
  const [returnSuccess, setReturnSuccess] = useState(false);

  if (!isOpen || !order) return null;

  const handleDownloadInvoice = () => {
    const invoiceContent = `
=========================================
          REXO PLATFORM INVOICE          
=========================================
Invoice Number: INV-${order.orderNumber}
Order Reference: ${order.orderNumber}
Date: ${new Date(order.createdAt).toLocaleDateString()}
Status: ${order.orderStatus.toUpperCase()}

CUSTOMER DETAILS:
Name: ${order.shippingAddress?.fullName || 'Verified Customer'}
Phone: ${order.shippingAddress?.phone || 'N/A'}
Address: ${order.shippingAddress?.street || ''}, ${order.shippingAddress?.city || ''} ${order.shippingAddress?.pincode || ''}

ITEMS ORDERED:
${order.items
  .map(
    (item, idx) =>
      `${idx + 1}. [${item.itemType.toUpperCase()}] ${item.title}\n   Qty: ${item.quantity} x ₹${item.price} = ₹${item.price * item.quantity}`
  )
  .join('\n')}

-----------------------------------------
Subtotal: ₹${order.totalAmount}
Payment Method: ${order.paymentMethod.toUpperCase()}
Payment Status: ${order.paymentStatus.toUpperCase()}
GST (18% Included): ₹${Math.round(order.totalAmount * 0.18)}
Total Paid: ₹${order.totalAmount}
-----------------------------------------
Thank you for building with Rexo Store!
Official B2B Support: support@rexo.in
=========================================
`;
    const blob = new Blob([invoiceContent], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Invoice_${order.orderNumber}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  const handleInitiateReturn = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProductId || !returnReason.trim()) return;
    const res = createReturnRequest(order.id, selectedProductId, returnReason);
    if (res.success) {
      setReturnSuccess(true);
      setTimeout(() => {
        setReturnSuccess(false);
        setIsReturnModalOpen(false);
        onClose();
      }, 1500);
    }
  };

  const getTimelineSteps = () => {
    const isShipped = order.orderStatus === 'shipped' || order.orderStatus === 'delivered';
    const isDelivered = order.orderStatus === 'delivered';

    return [
      {
        title: 'Order Confirmed',
        desc: `Verified payment via ${order.paymentMethod.toUpperCase()}`,
        time: new Date(order.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        completed: true,
      },
      {
        title: 'Dispatched & Courier Handover',
        desc: order.courierName
          ? `Dispatched via ${order.courierName} (AWB: ${order.trackingNumber || 'PENDING'})`
          : 'Processing package with verified merchant',
        time: isShipped ? 'In Transit' : 'Processing',
        completed: isShipped,
      },
      {
        title: 'Out for Delivery / Fulfilled',
        desc: isDelivered ? 'Delivered to shipping destination' : 'Estimated transit time 2-3 business days',
        time: isDelivered ? 'Completed' : 'Pending',
        completed: isDelivered,
      },
    ];
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
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-bold text-slate-900">{order.orderNumber}</h3>
                <span
                  className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md ${
                    order.orderStatus === 'delivered'
                      ? 'bg-emerald-50 text-emerald-700'
                      : order.orderStatus === 'shipped'
                      ? 'bg-blue-50 text-blue-700'
                      : 'bg-amber-50 text-amber-700'
                  }`}
                >
                  {order.orderStatus}
                </span>
              </div>
              <p className="text-xs text-slate-500 font-medium mt-0.5">
                Placed on {new Date(order.createdAt).toLocaleDateString()}
              </p>
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
            {/* Tracking Timeline */}
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100/80 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
                  Fulfillment Status
                </span>
                {order.trackingNumber && (
                  <span className="text-xs font-mono font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded-md">
                    AWB: {order.trackingNumber}
                  </span>
                )}
              </div>

              <div className="space-y-3 relative pl-4 border-l-2 border-slate-200 ml-2">
                {getTimelineSteps().map((step, idx) => (
                  <div key={idx} className="relative">
                    <div
                      className={`bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95`}
                    />
                    <div className="flex items-start justify-between">
                      <h5
                        className={`text-xs font-bold ${
                          step.completed ? 'text-slate-900' : 'text-slate-400'
                        }`}
                      >
                        {step.title}
                      </h5>
                      <span className="text-[10px] font-medium text-slate-500">{step.time}</span>
                    </div>
                    <p className="text-[11px] text-slate-500 font-medium mt-0.5 leading-relaxed">
                      {step.desc}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            {/* Ordered Items List */}
            <div>
              <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-2.5">
                Ordered Items ({order.items.length})
              </h4>
              <div className="space-y-2">
                {order.items.map((item, idx) => (
                  <div
                    key={idx}
                    className="p-3 rounded-2xl border border-slate-100 bg-white flex items-center justify-between gap-3 shadow-xs"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      {item.image ? (
                        <img
                          src={item.image}
                          alt={item.title}
                          referrerPolicy="no-referrer"
                          className="w-12 h-12 rounded-xl object-cover shrink-0"
                        />
                      ) : (
                        <div className="w-12 h-12 rounded-xl bg-slate-100 flex items-center justify-center text-slate-400 shrink-0">
                          <Package size={20} />
                        </div>
                      )}
                      <div className="min-w-0">
                        <span className="text-[9px] font-bold uppercase tracking-wider text-indigo-600 bg-indigo-50 px-1.5 py-0.5 rounded">
                          {item.itemType}
                        </span>
                        <h5 className="text-xs font-bold text-slate-900 truncate mt-0.5">
                          {item.title}
                        </h5>
                        <p className="text-[11px] text-slate-500 font-medium">
                          Qty: {item.quantity} • ₹{item.price} each
                        </p>
                      </div>
                    </div>
                    <span className="text-xs font-bold text-slate-900 shrink-0">
                      ₹{item.price * item.quantity}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Shipping Address */}
            {order.shippingAddress && (
              <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                <div className="flex items-center gap-2 mb-1">
                  <MapPin size={14} className="text-indigo-600" />
                  <span className="text-xs font-bold text-slate-800">Delivery Address</span>
                </div>
                <p className="text-xs text-slate-600 font-medium leading-relaxed pl-5">
                  {order.shippingAddress.fullName} • {order.shippingAddress.phone}
                  <br />
                  {order.shippingAddress.street}, {order.shippingAddress.city}, {order.shippingAddress.state} - {order.shippingAddress.pincode}
                </p>
              </div>
            )}

            {/* Payment Summary */}
            <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 space-y-1.5">
              <div className="flex justify-between text-xs font-medium text-slate-600">
                <span>Payment Mode</span>
                <span className="font-bold text-slate-900 uppercase">{order.paymentMethod}</span>
              </div>
              <div className="flex justify-between text-xs font-medium text-slate-600">
                <span>Payment Status</span>
                <span className="font-bold text-emerald-700 uppercase">{order.paymentStatus}</span>
              </div>
              <div className="flex justify-between text-sm font-bold text-slate-900 pt-2 border-t border-slate-200">
                <span>Total Amount</span>
                <span>₹{order.totalAmount}</span>
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-3 pt-2">
              <button
                onClick={handleDownloadInvoice}
                className="flex-1 py-2 rounded-xl border border-slate-200 hover:border-slate-300 bg-white text-slate-800 font-bold text-xs shadow-xs transition-colors flex items-center justify-center gap-2"
              >
                <Download size={14} />
                <span>GST Tax Invoice</span>
              </button>

              {order.orderStatus === 'delivered' && (
                <button
                  onClick={() => {
                    setSelectedProductId(order.items[0]?.referenceId || '');
                    setIsReturnModalOpen(true);
                  }}
                  className="flex-1 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs shadow-xs transition-colors flex items-center justify-center gap-2"
                >
                  <RotateCcw size={14} />
                  <span>Return / Replace</span>
                </button>
              )}
            </div>

            {/* Return Request Sub-Modal */}
            {isReturnModalOpen && (
              <div className="p-4 rounded-2xl bg-amber-50/80 border border-amber-200 space-y-3">
                <div className="flex items-center justify-between">
                  <h5 className="text-xs font-bold text-amber-900">Request Item Return</h5>
                  <button
                    onClick={() => setIsReturnModalOpen(false)}
                    className="text-amber-700 hover:text-amber-900 text-xs font-medium"
                  >
                    Cancel
                  </button>
                </div>

                {returnSuccess ? (
                  <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200 text-center text-xs font-bold text-emerald-800">
                    Return request submitted! Seller has been notified.
                  </div>
                ) : (
                  <form onSubmit={handleInitiateReturn} className="space-y-2.5">
                    <div>
                      <label className="text-[11px] font-bold text-slate-700 block mb-1">
                        Select Product
                      </label>
                      <select
                        value={selectedProductId}
                        onChange={(e) => setSelectedProductId(e.target.value)}
                        className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-800"
                      >
                        {order.items.map((it) => (
                          <option key={it.referenceId} value={it.referenceId}>
                            {it.title} (₹{it.price})
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="text-[11px] font-bold text-slate-700 block mb-1">
                        Reason for Return
                      </label>
                      <textarea
                        required
                        rows={2}
                        value={returnReason}
                        onChange={(e) => setReturnReason(e.target.value)}
                        placeholder="e.g. Defective hardware component / Missing accessories"
                        className="w-full bg-white border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-800"
                      />
                    </div>

                    <button
                      type="submit"
                      className="w-full py-2.5 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs transition-colors"
                    >
                      Submit Return Request
                    </button>
                  </form>
                )}
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
