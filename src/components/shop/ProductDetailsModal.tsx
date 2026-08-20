import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { StoreProduct, ShippingAddress } from '../../types';
import {
  X,
  Star,
  Download,
  ShoppingCart,
  Zap,
  CheckCircle2,
  Copy,
  Share2,
  Heart,
  ExternalLink,
  Truck,
  ShieldCheck,
  ChevronLeft,
  ChevronRight,
  FileText,
  Key,
  MapPin,
  Check,
} from 'lucide-react';

interface ProductDetailsModalProps {
  product: StoreProduct;
  onClose: () => void;
  onShowToast: (msg: string) => void;
}

export const ProductDetailsModal: React.FC<ProductDetailsModalProps> = ({
  product,
  onClose,
  onShowToast,
}) => {
  const {
    state,
    currentUser,
    addToCart,
    toggleWishlist,
    checkoutOrder,
  } = useStore();

  const wishlist = state.wishlist || [];
  const isWishlisted = wishlist.includes(product.id);

  // Gallery Index
  const gallery = [product.coverImage, ...(product.galleryImages || [])].filter(Boolean);
  const [activeImageIdx, setActiveImageIdx] = useState(0);

  // Physical Options
  const [selectedColor, setSelectedColor] = useState(product.colors?.[0] || '');
  const [selectedSize, setSelectedSize] = useState(product.sizes?.[0] || '');

  // Address Modal for Physical Product Checkout
  const [showAddressModal, setShowAddressModal] = useState(false);
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

  const [paymentMethod, setPaymentMethod] = useState<'Wallet' | 'UPI' | 'Card'>('UPI');
  const [copiedTitle, setCopiedTitle] = useState(false);
  const [copiedDesc, setCopiedDesc] = useState(false);

  // Instant Purchase Handler
  const handleInstantBuy = () => {
    if (product.productType === 'physical_product') {
      // Physical product requires shipping address
      setShowAddressModal(true);
    } else {
      // Digital or Free Resource product -> Instant checkout with zero friction
      const res = checkoutOrder({
        items: [{ product, quantity: 1 }],
        paymentMethod: product.isFree ? 'Free Download' : 'Wallet Escrow',
      });

      if (res.success) {
        onShowToast(res.message);
        onClose();
      }
    }
  };

  // Physical Address Submission Handler
  const handlePhysicalCheckoutSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!addressForm.fullName || !addressForm.mobile || !addressForm.address || !addressForm.pincode) {
      alert('Please fill out all required shipping address fields.');
      return;
    }

    const res = checkoutOrder({
      items: [
        {
          product,
          quantity: 1,
          selectedColor,
          selectedSize,
        },
      ],
      shippingAddress: addressForm,
      paymentMethod,
    });

    if (res.success) {
      onShowToast(res.message);
      setShowAddressModal(false);
      onClose();
    }
  };

  const handleCopyTitle = () => {
    navigator.clipboard.writeText(product.title);
    setCopiedTitle(true);
    onShowToast('Title copied to clipboard');
    setTimeout(() => setCopiedTitle(false), 2000);
  };

  const handleCopyDesc = () => {
    navigator.clipboard.writeText(product.fullDescription);
    setCopiedDesc(true);
    onShowToast('Description copied to clipboard');
    setTimeout(() => setCopiedDesc(false), 2000);
  };

  const handleShare = () => {
    const shareUrl = window.location.href;
    if (navigator.share) {
      navigator.share({ title: product.title, text: product.shortDescription, url: shareUrl });
    } else {
      navigator.clipboard.writeText(shareUrl);
      onShowToast('Product link copied to clipboard!');
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-3 sm:p-4 overflow-y-auto">
      <div className="bg-white dark:bg-slate-900 rounded-3xl max-w-xl w-full max-h-[90vh] overflow-y-auto border border-slate-200 dark:border-slate-800 shadow-2xl text-slate-900 dark:text-white relative my-auto">
        {/* TOP BAR */}
        <div className="sticky top-0 z-10 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md px-5 py-3.5 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
          <span className="text-xs font-black uppercase tracking-wider text-indigo-600 dark:text-indigo-400">
            {product.category}
          </span>
          <div className="flex items-center gap-2">
            <button
              onClick={() => toggleWishlist(product.id)}
              className={`p-2 rounded-full transition-all active:scale-95 ${
                isWishlisted
                  ? 'bg-rose-500 text-white'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
              }`}
              title="Wishlist"
            >
              <Heart size={16} className={isWishlisted ? 'fill-white' : ''} />
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200"
            >
              <X size={18} />
            </button>
          </div>
        </div>

        <div className="p-5 space-y-5">
          {/* GALLERY CAROUSEL */}
          <div className="relative aspect-16/10 rounded-2xl bg-slate-100 dark:bg-slate-800 overflow-hidden group">
            <img
              src={gallery[activeImageIdx] || product.coverImage}
              alt={product.title}
              className="w-full h-full object-cover"
            />

            {gallery.length > 1 && (
              <>
                <button
                  onClick={() => setActiveImageIdx((prev) => (prev > 0 ? prev - 1 : gallery.length - 1))}
                  className="absolute left-2 top-1/2 -translate-y-1/2 p-2 rounded-full bg-slate-900/70 text-white hover:bg-slate-900 transition-all"
                >
                  <ChevronLeft size={16} />
                </button>
                <button
                  onClick={() => setActiveImageIdx((prev) => (prev < gallery.length - 1 ? prev + 1 : 0))}
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-2 rounded-full bg-slate-900/70 text-white hover:bg-slate-900 transition-all"
                >
                  <ChevronRight size={16} />
                </button>
              </>
            )}
          </div>

          {/* GALLERY THUMBNAILS */}
          {gallery.length > 1 && (
            <div className="flex items-center gap-2 overflow-x-auto pb-1">
              {gallery.map((img, idx) => (
                <button
                  key={idx}
                  onClick={() => setActiveImageIdx(idx)}
                  className={`w-14 h-14 rounded-xl overflow-hidden border-2 transition-all shrink-0 ${
                    activeImageIdx === idx ? 'border-indigo-600' : 'border-transparent opacity-70'
                  }`}
                >
                  <img src={img} alt="thumb" className="w-full h-full object-cover" />
                </button>
              ))}
            </div>
          )}

          {/* TITLE & RATING & PRICING */}
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-1.5 text-xs text-amber-500 font-bold">
                <Star size={14} className="fill-amber-500" />
                <span>{product.rating}</span>
                <span className="text-slate-400">({product.salesCount} purchases)</span>
              </div>

              {product.isFree ? (
                <span className="px-3 py-1 bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300 text-xs font-black rounded-full">
                  FREE RESOURCE
                </span>
              ) : (
                <span className="px-3 py-1 bg-indigo-50 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 text-xs font-bold rounded-full uppercase">
                  {product.productType.replace('_', ' ')}
                </span>
              )}
            </div>

            <h2 className="text-xl font-black text-slate-900 dark:text-white leading-tight">
              {product.title}
            </h2>

            {/* PRICING DISPLAY */}
            <div className="flex items-baseline gap-2 pt-1">
              <span className="text-2xl font-black text-slate-900 dark:text-white">
                {product.isFree ? '₹0' : `₹${product.price}`}
              </span>
              {product.discountPrice && !product.isFree && (
                <span className="text-sm text-slate-400 line-through font-bold">
                  ₹{product.discountPrice}
                </span>
              )}
            </div>
          </div>

          {/* PHYSICAL PRODUCT COLOR & SIZE OPTIONS */}
          {product.productType === 'physical_product' && (
            <div className="p-4 bg-slate-50 dark:bg-slate-800/60 rounded-2xl space-y-3 text-xs">
              {product.colors && product.colors.length > 0 && (
                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1.5">
                    Select Color
                  </label>
                  <div className="flex items-center gap-2">
                    {product.colors.map((c) => (
                      <button
                        key={c}
                        onClick={() => setSelectedColor(c)}
                        className={`bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95`}
                      >
                        {c}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {product.sizes && product.sizes.length > 0 && (
                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1.5">
                    Select Size
                  </label>
                  <div className="flex items-center gap-2">
                    {product.sizes.map((s) => (
                      <button
                        key={s}
                        onClick={() => setSelectedSize(s)}
                        className={`bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95`}
                      >
                        {s}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              <div className="flex items-center gap-2 text-[11px] text-slate-500 font-medium pt-1">
                <Truck size={14} className="text-indigo-600 shrink-0" />
                <span>
                  Delivery in {product.estimatedDelivery || '3-5 days'} | Free Pan-India Shipping
                </span>
              </div>
            </div>
          )}

          {/* DESCRIPTION */}
          <div className="space-y-1.5">
            <h4 className="text-xs font-black text-slate-900 dark:text-white uppercase tracking-wider">
              Description
            </h4>
            <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed font-medium">
              {product.fullDescription}
            </p>
          </div>

          {/* FEATURES INCLUDED */}
          {product.featuresIncluded && product.featuresIncluded.length > 0 && (
            <div className="space-y-2">
              <h4 className="text-xs font-black text-slate-900 dark:text-white uppercase tracking-wider">
                What's Included
              </h4>
              <ul className="grid grid-cols-1 gap-1.5 text-xs font-medium text-slate-700 dark:text-slate-300">
                {product.featuresIncluded.map((feat, idx) => (
                  <li key={idx} className="flex items-start gap-2">
                    <CheckCircle2 size={15} className="text-emerald-500 shrink-0 mt-0.5" />
                    <span>{feat}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* UTILITY COPY / SHARE BUTTONS */}
          <div className="flex items-center gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
            <button
              onClick={handleCopyTitle}
              className="flex-1 py-2 px-3 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-300 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-all"
            >
              {copiedTitle ? <Check size={14} /> : <Copy size={14} />} Copy Title
            </button>

            <button
              onClick={handleCopyDesc}
              className="flex-1 py-2 px-3 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-300 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-all"
            >
              {copiedDesc ? <Check size={14} /> : <Copy size={14} />} Copy Details
            </button>

            <button
              onClick={handleShare}
              className="p-2 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-300 rounded-xl text-xs font-bold flex items-center justify-center transition-all"
              title="Share"
            >
              <Share2 size={16} />
            </button>
          </div>

          {/* PRIMARY PURCHASE BUTTONS */}
          <div className="flex items-center gap-2 pt-2">
            {product.productType === 'physical_product' && (
              <button
                onClick={() => {
                  addToCart(product, 1, selectedColor, selectedSize);
                  onShowToast('Added to cart!');
                }}
                className="py-3 px-4 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-900 dark:text-white rounded-2xl text-xs font-extrabold transition-all active:scale-95 flex items-center gap-2 shadow-2xs"
              >
                <ShoppingCart size={16} /> Add To Cart
              </button>
            )}

            <button
              onClick={handleInstantBuy}
              className="flex-1 py-2 px-3.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-black transition-all active:scale-95 flex items-center justify-center gap-2 shadow-md"
            >
              <Zap size={16} />
              <span>
                {product.isFree
                  ? 'Instant Free Download'
                  : `Buy Now • ${product.productType === 'physical_product' ? 'Enter Address' : `₹${product.price}`}`}
              </span>
            </button>
          </div>
        </div>
      </div>

      {/* PHYSICAL PRODUCT SHIPPING ADDRESS FORM MODAL */}
      {showAddressModal && (
        <div className="fixed inset-0 z-[60] bg-slate-950/80 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-md w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-2xl text-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white flex items-center gap-2">
                <MapPin size={18} className="text-indigo-600" /> Enter Shipping Address
              </h3>
              <button
                onClick={() => setShowAddressModal(false)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handlePhysicalCheckoutSubmit} className="space-y-3">
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
                    Mobile Number *
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
                  Email Address *
                </label>
                <input
                  type="email"
                  required
                  value={addressForm.email}
                  onChange={(e) => setAddressForm({ ...addressForm, email: e.target.value })}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Full Address (House / Building / Street) *
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

              <div className="pt-2">
                <button
                  type="submit"
                  className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
                >
                  Confirm & Place Order (₹{product.price})
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
