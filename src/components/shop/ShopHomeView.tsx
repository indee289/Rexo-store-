import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { StoreProduct, StoreProductType, SubscriptionPlan } from '../../types';
import {
  Search,
  ShoppingCart,
  Heart,
  PackageCheck,
  Star,
  Download,
  Sparkles,
  Truck,
  Briefcase,
  CheckCircle2,
  ChevronRight,
  Plus,
  ShieldCheck,
  Copy,
  Share2,
  ExternalLink,
  SlidersHorizontal,
  X,
  Check,
  Crown,
} from 'lucide-react';
import { ProductDetailsModal } from './ProductDetailsModal';
import { CartDrawer } from './CartDrawer';
import { MyPurchasesView } from './MyPurchasesView';
import { AdminShopCenter } from './AdminShopCenter';
import { PageHeader, EmptyState, FilterPill } from '../ui';

interface ShopHomeViewProps {
  onNavigateNotifications?: () => void;
}

export const ShopHomeView: React.FC<ShopHomeViewProps> = () => {
  const {
    state,
    currentUser,
    addToCart,
    toggleWishlist,
    subscribeToPlan,
  } = useStore();

  const isAdmin = currentUser.role === 'admin';

  // State controls
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedProduct, setSelectedProduct] = useState<StoreProduct | null>(null);
  const [showCartDrawer, setShowCartDrawer] = useState(false);
  const [showMyPurchases, setShowMyPurchases] = useState(false);
  const [showAdminCenter, setShowAdminCenter] = useState(false);

  // Feedback Toast
  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3000);
  };

  const products = state.products || [];
  const cart = state.cart || [];
  const wishlist = state.wishlist || [];
  const subscriptionPlans = state.subscriptionPlans || [];
  const userSubscriptions = state.userSubscriptions || [];

  const activeSub = userSubscriptions.find(
    (s) => s.userId === currentUser.id && s.status === 'active'
  );

  // Filtered Products
  const visibleProducts = products.filter((p) => p.isVisible !== false && p.status === 'active');

  const filteredProducts = visibleProducts.filter((p) => {
    const query = (searchQuery || '').toLowerCase();
    const matchesSearch =
      (p.title || '').toLowerCase().includes(query) ||
      (p.shortDescription || '').toLowerCase().includes(query) ||
      (p.category || '').toLowerCase().includes(query);

    if (!matchesSearch) return false;

    if (selectedCategory === 'all') return true;
    if (selectedCategory === 'free') return p.isFree || p.productType === 'free_resource';
    if (selectedCategory === 'digital') return p.productType === 'digital_product';
    if (selectedCategory === 'physical') return p.productType === 'physical_product';
    if (selectedCategory === 'service') return p.productType === 'service_package';
    if (selectedCategory === 'subscription') return p.productType === 'subscription_plan';

    return (p.category || '').toLowerCase() === selectedCategory.toLowerCase();
  });

  const featuredProducts = visibleProducts.filter((p) => p.isFeatured);
  const digitalProducts = visibleProducts.filter((p) => p.productType === 'digital_product');
  const physicalProducts = visibleProducts.filter((p) => p.productType === 'physical_product');
  const servicePackages = visibleProducts.filter((p) => p.productType === 'service_package');
  const freeResources = visibleProducts.filter((p) => p.isFree || p.productType === 'free_resource');

  // Handle subscribe action
  const handleSubscribe = (plan: SubscriptionPlan) => {
    const res = subscribeToPlan(plan.id);
    if (res.success) {
      showToast(res.message);
    }
  };

  if (showMyPurchases) {
    return <MyPurchasesView onBack={() => setShowMyPurchases(false)} />;
  }

  if (showAdminCenter && isAdmin) {
    return <AdminShopCenter onBack={() => setShowAdminCenter(false)} />;
  }

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans transition-colors">
      <div className="max-w-3xl mx-auto px-4 space-y-5">
        {/* HEADER: TITLE & SHOP UTILITIES */}
        <PageHeader 
          title="Rexo Store"
          actions={
            <>
              {/* My Purchases Button */}
              <button
                onClick={() => setShowMyPurchases(true)}
                className="px-3.5 py-2 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 relative shadow-2xs hover:bg-slate-50 transition-all active:scale-95 flex items-center gap-1.5 text-xs font-semibold"
                title="My Purchases"
              >
                <PackageCheck size={18} />
                <span className="hidden sm:inline">My Purchases</span>
              </button>

              {/* Cart Button */}
              <button
                onClick={() => setShowCartDrawer(true)}
                className="px-3.5 py-2 rounded-full bg-indigo-600 text-white relative shadow-md hover:bg-indigo-700 transition-all active:scale-95 flex items-center gap-1.5 text-xs font-bold"
                title="Cart"
              >
                <ShoppingCart size={18} />
                {cart.length > 0 && (
                  <span className="bg-rose-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full ring-2 ring-white dark:ring-slate-900">
                    {cart.length}
                  </span>
                )}
              </button>
            </>
          }
        />

        {/* FEEDBACK TOAST */}
        {toastMsg && (
          <div className="p-3.5 bg-emerald-50 dark:bg-emerald-950/80 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200 text-xs font-bold rounded-2xl flex items-center justify-between shadow-2xs">
            <span>{toastMsg}</span>
            <button onClick={() => setToastMsg(null)}>
              <X size={14} />
            </button>
          </div>
        )}

        {/* CATEGORY FILTERS */}
        <div className="space-y-3">
          {/* Category Filter Pills */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 no-scrollbar text-xs font-bold">
            {[
              { id: 'all', label: 'All Items' },
              { id: 'free', label: '🎁 Free Resources' },
              { id: 'digital', label: '⚡ Digital & AI Bundles' },
              { id: 'physical', label: '👕 Merch & Gadgets' },
              { id: 'service', label: '🚀 Growth Services' },
            ].map((cat) => (
              <FilterPill
                key={cat.id}
                label={cat.label}
                isActive={selectedCategory === cat.id}
                onClick={() => setSelectedCategory(cat.id)}
              />
            ))}
          </div>
        </div>

        {/* 1. CATALOG PRODUCTS GRID */}
        <div className="space-y-3 pt-2">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-extrabold text-slate-900 dark:text-white">
              {selectedCategory === 'all'
                ? 'Catalog & Marketplace Products'
                : `Filtered Results (${filteredProducts.length})`}
            </h2>
            <span className="text-[11px] font-bold text-slate-400">
              {filteredProducts.length} Items Available
            </span>
          </div>

          {filteredProducts.length === 0 ? (
            <EmptyState 
              icon={<PackageCheck size={24} />}
              title="No products found"
              description="No products match your search or filter."
            />
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
              {filteredProducts.map((product) => {
                const isWishlisted = wishlist.includes(product.id);
                return (
                  <div
                    key={product.id}
                    onClick={() => setSelectedProduct(product)}
                    className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/90 dark:border-slate-800/90 overflow-hidden shadow-xs hover:shadow-md transition-all flex flex-col group cursor-pointer"
                  >
                    {/* Product Image Container */}
                    <div className="relative aspect-square bg-slate-100 dark:bg-slate-800 overflow-hidden">
                      <img
                        src={product.coverImage}
                        alt={product.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                      
                      {/* Top Badges */}
                      <div className="absolute top-2 left-2 flex flex-col gap-1.5 items-start">
                        {product.isFree ? (
                          <span className="bg-emerald-600 text-white text-[9px] font-bold px-2 py-0.5 rounded-full shadow-xs uppercase tracking-wider">
                            FREE
                          </span>
                        ) : product.discountPrice ? (
                          <span className="bg-rose-600 text-white text-[9px] font-bold px-2 py-0.5 rounded-full shadow-xs uppercase tracking-wider">
                            SAVE ₹{product.discountPrice - product.price}
                          </span>
                        ) : null}
                      </div>

                      {/* Wishlist Button */}
                      <button
                        onClick={(e) => { e.stopPropagation(); toggleWishlist(product.id); }}
                        className={`absolute bottom-2 right-2 p-1.5 rounded-full backdrop-blur-md transition-all active:scale-95 ${
                          isWishlisted
                            ? 'bg-rose-500 text-white'
                            : 'bg-white/90 dark:bg-slate-900/90 text-slate-700 dark:text-slate-200'
                        }`}
                      >
                        <Heart size={13} className={isWishlisted ? 'fill-white' : ''} />
                      </button>
                    </div>

                    {/* Content */}
                    <div className="p-3 flex flex-col flex-1 justify-between gap-2">
                      <div className="space-y-1">
                        <div className="flex items-center gap-1 text-[10px] text-amber-500 font-bold">
                          <Star size={10} className="fill-amber-500" />
                          <span>{product.rating}</span>
                          <span className="text-slate-400 font-medium">({product.salesCount})</span>
                        </div>

                        <h3 className="text-xs font-bold text-slate-900 dark:text-white leading-tight line-clamp-2 group-hover:text-indigo-600 transition-colors">
                          {product.title}
                        </h3>
                      </div>

                      <div className="pt-2 border-t border-slate-100 dark:border-slate-800/80">
                        {product.isFree ? (
                          <span className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
                            ₹0
                          </span>
                        ) : (
                          <div className="flex flex-wrap items-baseline gap-1.5">
                            <span className="text-xs font-bold text-slate-900 dark:text-white">
                              ₹{product.price}
                            </span>
                            {product.discountPrice && (
                              <span className="text-[10px] text-slate-400 font-medium line-through">
                                ₹{product.discountPrice}
                              </span>
                            )}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* PRODUCT DETAILS MODAL */}
      {selectedProduct && (
        <ProductDetailsModal
          product={selectedProduct}
          onClose={() => setSelectedProduct(null)}
          onShowToast={showToast}
        />
      )}

      {/* CART DRAWER */}
      {showCartDrawer && (
        <CartDrawer
          onClose={() => setShowCartDrawer(false)}
          onShowToast={showToast}
          onOpenMyPurchases={() => {
            setShowCartDrawer(false);
            setShowMyPurchases(true);
          }}
        />
      )}
    </div>
  );
};
