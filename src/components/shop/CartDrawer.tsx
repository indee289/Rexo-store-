import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { ShippingAddress } from '../../types';
import {
  X,
  Trash2,
  Plus,
  Minus,
  ShoppingCart,
  MapPin,
  ArrowRight,
  ShieldCheck,
  CheckCircle2,
} from 'lucide-react';

interface CartDrawerProps {
  onClose: () => void;
  onShowToast: (msg: string) => void;
  onOpenMyPurchases: () => void;
}

export const CartDrawer: React.FC<CartDrawerProps> = ({
  onClose,
  onShowToast,
  onOpenMyPurchases,
}) => {
  const {
    state,
    currentUser,
    removeFromCart,
    clearCart,
    checkoutOrder,
  } = useStore();

  const cart = state.cart || [];

  const [showAddressForm, setShowAddressForm] = useState(false);
  const [addressForm, setAddressForm] = useState<ShippingAddress>({
    fullName: currentUser.name || '',
    mobile: currentUser.phone || '',
    email: currentUser.email || '',
    country: 'India',
    state: '',
    city: '',
    address: '',
    landmark: '',
    pincode: '',
  });

  const [paymentMethod, setPaymentMethod] = useState<'UPI' | 'Wallet' | 'Card'>('UPI');

  const totalAmount = cart.reduce((sum, ci) => sum + ci.product.price * ci.quantity, 0);
  const hasPhysicalItems = cart.some((ci) => ci.product.productType === 'physical_product');

  const handleProceedCheckout = () => {
    if (cart.length === 0) return;

    if (hasPhysicalItems) {
      setShowAddressForm(true);
    } else {
      // Digital items only
      const res = checkoutOrder({
        items: cart.map((ci) => ({
          product: ci.product,
          quantity: ci.quantity,
          selectedColor: ci.selectedColor,
          selectedSize: ci.selectedSize,
        })),
        paymentMethod,
      });

      if (res.success) {
        onShowToast(res.message);
        onOpenMyPurchases();
      }
    }
  };

  const handleAddressSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!addressForm.fullName || !addressForm.mobile || !addressForm.address || !addressForm.pincode) {
      alert('Please fill out all required shipping address fields.');
      return;
    }

    const res = checkoutOrder({
      items: cart.map((ci) => ({
        product: ci.product,
        quantity: ci.quantity,
        selectedColor: ci.selectedColor,
        selectedSize: ci.selectedSize,
      })),
      shippingAddress: addressForm,
      paymentMethod,
    });

    if (res.success) {
      onShowToast(res.message);
      onOpenMyPurchases();
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex justify-end">
      <div className="bg-white dark:bg-slate-900 w-full max-w-md h-full shadow-2xl flex flex-col justify-between border-l border-slate-200 dark:border-slate-800 text-slate-900 dark:text-white transition-all">
        {/* HEADER */}
        <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShoppingCart size={20} className="text-indigo-600 dark:text-indigo-400" />
            <h2 className="text-base font-extrabold">Your Cart ({cart.length})</h2>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-400 hover:text-slate-600"
          >
            <X size={18} />
          </button>
        </div>

        {/* CART CONTENT */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {cart.length === 0 ? (
            <div className="p-10 text-center space-y-3 text-slate-400 my-auto">
              <ShoppingCart size={40} className="mx-auto text-slate-300 dark:text-slate-700" />
              <p className="text-xs font-bold text-slate-600 dark:text-slate-400">
                Your cart is empty. Explore the store and add items!
              </p>
            </div>
          ) : (
            cart.map((item, idx) => (
              <div
                key={idx}
                className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-2xl border border-slate-200/80 dark:border-slate-700/80 flex items-center justify-between gap-3 text-xs"
              >
                <img
                  src={item.product.coverImage}
                  alt={item.product.title}
                  className="w-14 h-14 rounded-xl object-cover shrink-0"
                />

                <div className="flex-1 min-w-0">
                  <h4 className="font-extrabold text-slate-900 dark:text-white truncate">
                    {item.product.title}
                  </h4>

                  <div className="text-[11px] text-slate-500 font-medium">
                    {item.selectedColor && <span>Color: {item.selectedColor} </span>}
                    {item.selectedSize && <span>| Size: {item.selectedSize}</span>}
                  </div>

                  <div className="font-black text-indigo-600 dark:text-indigo-400 mt-0.5">
                    ₹{item.product.price} x {item.quantity} = ₹{item.product.price * item.quantity}
                  </div>
                </div>

                <button
                  onClick={() => removeFromCart(item.productId)}
                  className="p-2 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-xl shrink-0"
                  title="Remove"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            ))
          )}
        </div>

        {/* FOOTER CHECKOUT SUMMARY */}
        {cart.length > 0 && (
          <div className="p-4 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50 space-y-3">
            <div className="space-y-1.5 text-xs font-bold">
              <div className="flex justify-between text-slate-500">
                <span>Subtotal</span>
                <span>₹{totalAmount}</span>
              </div>
              <div className="flex justify-between text-slate-500">
                <span>Shipping</span>
                <span className="text-emerald-600 font-bold">FREE</span>
              </div>
              <div className="flex justify-between text-sm font-black text-slate-900 dark:text-white pt-1 border-t border-slate-200 dark:border-slate-800">
                <span>Total Amount</span>
                <span>₹{totalAmount}</span>
              </div>
            </div>

            <button
              onClick={handleProceedCheckout}
              className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
            >
              <span>{hasPhysicalItems ? 'Enter Shipping Address' : 'Complete Instant Purchase'}</span>
              <ArrowRight size={16} />
            </button>
          </div>
        )}
      </div>

      {/* ADDRESS FORM MODAL (WHEN PHYSICAL ITEMS PRESENT) */}
      {showAddressForm && (
        <div className="fixed inset-0 z-[60] bg-slate-950/80 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-md w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-2xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white flex items-center gap-2">
                <MapPin size={18} className="text-indigo-600" /> Shipping Details
              </h3>
              <button
                onClick={() => setShowAddressForm(false)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleAddressSubmit} className="space-y-3">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    Full Name *
                  </label>
                  <input
                    type="text"
                    required
                    value={addressForm.fullName}
                    onChange={(e) => setAddressForm({ ...addressForm, fullName: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    Mobile *
                  </label>
                  <input
                    type="text"
                    required
                    value={addressForm.mobile}
                    onChange={(e) => setAddressForm({ ...addressForm, mobile: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Full Street Address *
                </label>
                <textarea
                  required
                  rows={2}
                  value={addressForm.address}
                  onChange={(e) => setAddressForm({ ...addressForm, address: e.target.value })}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    City *
                  </label>
                  <input
                    type="text"
                    required
                    value={addressForm.city}
                    onChange={(e) => setAddressForm({ ...addressForm, city: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2 text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    State *
                  </label>
                  <input
                    type="text"
                    required
                    value={addressForm.state}
                    onChange={(e) => setAddressForm({ ...addressForm, state: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2 text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    Pincode *
                  </label>
                  <input
                    type="text"
                    required
                    value={addressForm.pincode}
                    onChange={(e) => setAddressForm({ ...addressForm, pincode: e.target.value })}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2 text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>
              </div>

              <button
                type="submit"
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                Place Order (₹{totalAmount})
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
