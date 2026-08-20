import React, { useState, useRef } from 'react';
import { useStore } from '../../context/StoreContext';
import { StoreProduct, StoreProductType, StoreOrder } from '../../types';
import { r2StorageService } from '../../services/r2StorageService';
import {
  ArrowLeft,
  Plus,
  ShieldCheck,
  Package,
  TrendingUp,
  DollarSign,
  Download,
  Users,
  Edit,
  Trash2,
  Pause,
  Play,
  Eye,
  EyeOff,
  CheckCircle2,
  X,
  Sliders,
  Check,
  Upload,
  Image as ImageIcon,
} from 'lucide-react';

interface AdminShopCenterProps {
  onBack?: () => void;
  isEmbedded?: boolean;
}

export const AdminShopCenter: React.FC<AdminShopCenterProps> = ({ onBack, isEmbedded = false }) => {
  const {
    state,
    currentUser,
    createProduct,
    updateProduct,
    deleteProduct,
    adminUpdateOrderStatus,
    requestNativePermission,
  } = useStore();

  const isAdmin = currentUser.role === 'admin';

  const [activeTab, setActiveTab] = useState<'analytics' | 'products' | 'orders'>('products');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState<StoreProduct | null>(null);
  const [isUploading, setIsUploading] = useState(false);

  // Form states for Product creation
  const [title, setTitle] = useState('');
  const [productType, setProductType] = useState<StoreProductType>('digital_product');
  const [category, setCategory] = useState('AI Video Bundle');
  const [shortDesc, setShortDesc] = useState('');
  const [fullDesc, setFullDesc] = useState('');
  const [coverImage, setCoverImage] = useState('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop&q=80');
  const [price, setPrice] = useState(499);
  const [discountPrice, setDiscountPrice] = useState(999);
  const [stock, setStock] = useState(999);
  const productFileInputRef = useRef<HTMLInputElement>(null);

  const handleProductImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 10 * 1024 * 1024) {
        alert('Image size must be less than 10MB.');
        return;
      }
      setIsUploading(true);
      
      const { publicUrl, error } = await r2StorageService.uploadFile('product-images', file.name, file, file.type);
      
      if (error || !publicUrl) {
        alert('Failed to upload image. Please try again.');
      } else {
        setCoverImage(publicUrl);
      }
      setIsUploading(false);
    }
  };

  // Toggles
  const [isFree, setIsFree] = useState(false);
  const [isFeatured, setIsFeatured] = useState(true);
  const [isRecommended, setIsRecommended] = useState(true);
  const [isVisible, setIsVisible] = useState(true);

  // Digital Specific
  const [downloadUrl, setDownloadUrl] = useState('');
  const [driveUrl, setDriveUrl] = useState('');
  const [licenseKey, setLicenseKey] = useState('');

  // Physical Specific
  const [weight, setWeight] = useState('');
  const [sku, setSku] = useState('');

  // Analytics Math
  const products = state.products || [];
  const orders = state.orders || [];
  const userSubs = state.userSubscriptions || [];

  const totalRevenue = orders.reduce((sum, o) => sum + o.totalAmount, 0);
  const totalOrders = orders.length;
  const totalDownloads = orders.filter((o) => o.status === 'unlocked').length;
  const activeSubscribers = userSubs.filter((s) => s.status === 'active').length;

  if (!isAdmin) {
    return (
      <div className="p-10 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200 m-6">
        <h3 className="text-lg font-bold text-rose-600">Access Denied</h3>
        <p className="text-xs text-slate-500 mt-1">
          Only authorized platform administrators can access the Shop Management Center.
        </p>
        <button onClick={onBack} className="mt-4 px-4 py-2 bg-slate-900 text-white rounded-xl text-xs font-bold">
          Go Back
        </button>
      </div>
    );
  }

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !shortDesc) {
      alert('Please fill out required fields');
      return;
    }

    if (editingProduct) {
      updateProduct(editingProduct.id, {
        title,
        productType,
        category,
        shortDescription: shortDesc,
        fullDescription: fullDesc,
        coverImage,
        price: isFree ? 0 : Number(price),
        discountPrice: isFree ? 0 : Number(discountPrice),
        stock: Number(stock),
        isFree,
        isPaid: !isFree,
        isFeatured,
        isRecommended,
        isVisible,
        downloadUrl,
        driveUrl,
        licenseKey,
        weight,
        sku,
      });
      setEditingProduct(null);
    } else {
      createProduct({
        title,
        productType,
        category,
        shortDescription: shortDesc,
        fullDescription: fullDesc,
        coverImage,
        galleryImages: [coverImage],
        price: isFree ? 0 : Number(price),
        discountPrice: isFree ? 0 : Number(discountPrice),
        stock: Number(stock),
        tags: [category, productType],
        featuresIncluded: ['Instant Access / Delivery', 'Commercial License'],
        status: 'active',
        isFree,
        isPaid: !isFree,
        isFeatured,
        isRecommended,
        isVisible,
        downloadUrl,
        driveUrl,
        fileType: driveUrl ? 'Drive' : 'ZIP',
        licenseKey,
        weight,
        sku,
      });
    }

    setShowCreateModal(false);
    // Reset
    setTitle('');
    setShortDesc('');
    setFullDesc('');
  };

  const startEditProduct = (p: StoreProduct) => {
    setEditingProduct(p);
    setTitle(p.title);
    setProductType(p.productType);
    setCategory(p.category);
    setShortDesc(p.shortDescription);
    setFullDesc(p.fullDescription);
    setCoverImage(p.coverImage);
    setPrice(p.price);
    setDiscountPrice(p.discountPrice || 0);
    setStock(p.stock);
    setIsFree(p.isFree);
    setIsFeatured(p.isFeatured);
    setIsRecommended(p.isRecommended);
    setIsVisible(p.isVisible);
    setDownloadUrl(p.downloadUrl || '');
    setDriveUrl(p.driveUrl || '');
    setLicenseKey(p.licenseKey || '');
    setWeight(p.weight || '');
    setSku(p.sku || '');
    setShowCreateModal(true);
  };

  const content = (
    <div className="space-y-4">
      {/* HEADER */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {onBack && (
            <button
              onClick={onBack}
              className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 shadow-2xs hover:bg-slate-50 transition-all active:scale-95"
            >
              <ArrowLeft size={20} />
            </button>
          )}
          <div>
            <h1 className="text-xl font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-indigo-600 dark:text-indigo-400" /> Admin Shop Center
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
              Create & manage products, monitor orders and revenue
            </p>
          </div>
        </div>

        <button
          onClick={() => {
            setEditingProduct(null);
            setShowCreateModal(true);
          }}
          className="px-4 py-2.5 bg-slate-900 dark:bg-white text-white dark:text-slate-900 hover:bg-slate-800 rounded-2xl text-xs font-bold shadow-xs flex items-center gap-1.5 transition-all active:scale-95"
        >
          <Plus size={16} /> <span>Create Product</span>
        </button>
      </div>

        {/* ADMIN NAV TABS */}
        <div className="flex items-center gap-2 bg-white dark:bg-slate-900 p-1.5 rounded-2xl border border-slate-200/90 dark:border-slate-800 text-xs font-bold">
          <button
            onClick={() => setActiveTab('products')}
            className={`flex-1 py-2 rounded-xl transition-all ${
              activeTab === 'products'
                ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                : 'text-slate-500 hover:text-slate-900'
            }`}
          >
            Products ({products.length})
          </button>

          <button
            onClick={() => setActiveTab('orders')}
            className={`flex-1 py-2 rounded-xl transition-all ${
              activeTab === 'orders'
                ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                : 'text-slate-500 hover:text-slate-900'
            }`}
          >
            Orders ({orders.length})
          </button>

          <button
            onClick={() => setActiveTab('analytics')}
            className={`flex-1 py-2 rounded-xl transition-all ${
              activeTab === 'analytics'
                ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                : 'text-slate-500 hover:text-slate-900'
            }`}
          >
            Analytics
          </button>
        </div>

        {/* TAB 1: PRODUCTS CONTROL LIST */}
        {activeTab === 'products' && (
          <div className="space-y-3">
            {products.map((product) => (
              <div
                key={product.id}
                className="p-4 bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 flex items-center justify-between gap-3 text-xs shadow-2xs"
              >
                <img
                  src={product.coverImage}
                  alt={product.title}
                  className="w-14 h-14 rounded-2xl object-cover shrink-0"
                />

                <div className="flex-1 min-w-0 space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-[10px] font-black uppercase tracking-wider text-indigo-600 dark:text-indigo-400">
                      {product.category}
                    </span>
                    {!product.isVisible && (
                      <span className="px-2 py-0.5 bg-rose-100 text-rose-700 text-[9px] font-bold rounded-full">
                        Hidden
                      </span>
                    )}
                  </div>

                  <h3 className="font-extrabold text-slate-900 dark:text-white truncate">
                    {product.title}
                  </h3>

                  <div className="flex items-center gap-2 text-[11px] font-bold text-slate-500">
                    <span>Price: ₹{product.price}</span>
                    <span>• Sales: {product.salesCount}</span>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex items-center gap-1 shrink-0">
                  <button
                    onClick={() =>
                      updateProduct(product.id, { isVisible: product.isVisible === false ? true : false })
                    }
                    className="p-2 text-slate-400 hover:text-slate-600 dark:hover:text-white"
                    title="Toggle Visibility"
                  >
                    {product.isVisible ? <Eye size={16} /> : <EyeOff size={16} />}
                  </button>

                  <button
                    onClick={() => startEditProduct(product)}
                    className="p-2 text-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 rounded-xl"
                    title="Edit"
                  >
                    <Edit size={16} />
                  </button>

                  <button
                    onClick={() => {
                      deleteProduct(product.id);
                    }}
                    className="p-2 text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-xl"
                    title="Delete"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* TAB 2: ORDERS LIST */}
        {activeTab === 'orders' && (
          <div className="space-y-3">
            {orders.length === 0 ? (
              <div className="p-8 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200 text-xs text-slate-400">
                No orders recorded yet.
              </div>
            ) : (
              orders.map((order) => (
                <div
                  key={order.id}
                  className="p-4 bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 space-y-2 text-xs shadow-2xs"
                >
                  <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-2">
                    <div>
                      <strong className="block text-slate-900 dark:text-white">
                        {order.userName} ({order.userEmail})
                      </strong>
                      <span className="text-[10px] text-slate-400">
                        Order #{order.id.slice(-8)} • {new Date(order.createdAt).toLocaleString()}
                      </span>
                    </div>
                    <span className="font-extrabold text-sm text-slate-900 dark:text-white">
                      ₹{order.totalAmount}
                    </span>
                  </div>

                  <div className="flex items-center justify-between pt-1">
                    <span className="text-slate-500 font-medium">Status: {order.status}</span>
                    {order.productType === 'physical_product' && (
                      <div className="flex flex-wrap gap-1">
                        {(['pending', 'processing', 'shipped', 'delivered', 'cancelled'] as const).map((st) => (
                          <button
                            key={st}
                            type="button"
                            onClick={() => adminUpdateOrderStatus(order.id, st)}
                            className={`bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95`}
                          >
                            {st}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {/* TAB 3: ANALYTICS */}
        {activeTab === 'analytics' && (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div className="p-4 bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-2xs text-center space-y-1">
              <span className="text-[11px] font-bold text-slate-400 block">Total Revenue</span>
              <div className="text-xl font-black text-emerald-600">₹{totalRevenue}</div>
            </div>

            <div className="p-4 bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-2xs text-center space-y-1">
              <span className="text-[11px] font-bold text-slate-400 block">Total Orders</span>
              <div className="text-xl font-black text-indigo-600">{totalOrders}</div>
            </div>

            <div className="p-4 bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-2xs text-center space-y-1">
              <span className="text-[11px] font-bold text-slate-400 block">Total Unlocked</span>
              <div className="text-xl font-black text-amber-500">{totalDownloads}</div>
            </div>

            <div className="p-4 bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 shadow-2xs text-center space-y-1">
              <span className="text-[11px] font-bold text-slate-400 block">Active Subscribers</span>
              <div className="text-xl font-black text-rose-500">{activeSubscribers}</div>
            </div>
          </div>
        )}

        {/* CREATE / EDIT PRODUCT MODAL */}
        {showCreateModal && (
        <div className="fixed inset-0 z-[60] bg-slate-950/80 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-4 max-w-lg w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-2xl text-xs max-h-[90vh] overflow-y-auto my-auto">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
                {editingProduct ? 'Edit Product' : 'Create New Product'}
              </h3>
              <button onClick={() => setShowCreateModal(false)} className="text-slate-400">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleCreateSubmit} className="space-y-3">
              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1.5">
                  Product Type
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {[
                    { id: 'digital_product', label: 'Digital Product' },
                    { id: 'free_resource', label: 'Free Resource' },
                    { id: 'physical_product', label: 'Physical Product' },
                    { id: 'service_package', label: 'Service Package' },
                    { id: 'subscription_plan', label: 'Subscription Plan' },
                  ].map((pt) => {
                    const isSelected = productType === pt.id;
                    return (
                      <button
                        key={pt.id}
                        type="button"
                        onClick={() => setProductType(pt.id as any)}
                        className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1 ${
                          isSelected
                            ? 'bg-indigo-600 text-white shadow-xs'
                            : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-200'
                        }`}
                      >
                        {isSelected && <Check size={12} />}
                        <span>{pt.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Product Cover Image Upload */}
              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Upload Product Cover Image
                </label>
                <input
                  type="file"
                  ref={productFileInputRef}
                  accept="image/*"
                  onChange={handleProductImageUpload}
                  className="hidden"
                />

                <div
                  onClick={async (e) => {
                    e.preventDefault();
                    if (requestNativePermission) {
                      const allowed = await requestNativePermission('gallery');
                      if (allowed) productFileInputRef.current?.click();
                    } else {
                      productFileInputRef.current?.click();
                    }
                  }}
                  className="cursor-pointer border-2 border-dashed border-slate-300 dark:border-slate-700 hover:border-indigo-500 bg-slate-50 dark:bg-slate-800/80 rounded-2xl p-3 text-center transition-all flex items-center justify-center gap-2"
                >
                  <Upload size={16} className="text-indigo-600" />
                  <span className="font-bold text-slate-700 dark:text-slate-300">
                    Click to Upload Product Image
                  </span>
                </div>

                {coverImage && (
                  <div className="relative h-28 rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 mt-2">
                    <img src={coverImage} alt="Product Cover" className="w-full h-full object-cover" />
                    <button
                      type="button"
                      onClick={() => productFileInputRef.current?.click()}
                      className="absolute bottom-2 right-2 bg-slate-900/80 text-white text-[10px] font-bold px-2.5 py-1 rounded-xl backdrop-blur-xs"
                    >
                      Change Image
                    </button>
                  </div>
                )}
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Product Title *
                </label>
                <input
                  type="text"
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    Category
                  </label>
                  <input
                    type="text"
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    Price (₹)
                  </label>
                  <input
                    type="number"
                    disabled={isFree}
                    value={isFree ? 0 : price}
                    onChange={(e) => setPrice(Number(e.target.value))}
                    className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Short Description *
                </label>
                <input
                  type="text"
                  required
                  value={shortDesc}
                  onChange={(e) => setShortDesc(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Full Description
                </label>
                <textarea
                  rows={3}
                  value={fullDesc}
                  onChange={(e) => setFullDesc(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              {/* Digital Links */}
              {(productType === 'digital_product' || productType === 'free_resource') && (
                <div className="space-y-2 p-3 bg-slate-50 dark:bg-slate-800/60 rounded-2xl">
                  <div>
                    <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                      Google Drive Link (Drive URL)
                    </label>
                    <input
                      type="text"
                      placeholder="https://drive.google.com/..."
                      value={driveUrl}
                      onChange={(e) => setDriveUrl(e.target.value)}
                      className="w-full bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2 text-slate-900 dark:text-white focus:outline-none"
                    />
                  </div>

                  <div>
                    <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                      Direct Download ZIP/PDF Link
                    </label>
                    <input
                      type="text"
                      placeholder="https://rexomarket.app/downloads/file.zip"
                      value={downloadUrl}
                      onChange={(e) => setDownloadUrl(e.target.value)}
                      className="w-full bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-2 text-slate-900 dark:text-white focus:outline-none"
                    />
                  </div>
                </div>
              )}

              {/* Toggles */}
              <div className="grid grid-cols-2 gap-2 pt-1 font-bold text-slate-700 dark:text-slate-300">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={isFree}
                    onChange={(e) => setIsFree(e.target.checked)}
                  />
                  Free Resource
                </label>

                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={isFeatured}
                    onChange={(e) => setIsFeatured(e.target.checked)}
                  />
                  Featured Product
                </label>
              </div>

              <button
                type="submit"
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                {editingProduct ? 'Save Product Updates' : 'Publish Product to Store'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );

  if (isEmbedded) {
    return content;
  }

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans transition-colors">
      <div className="max-w-3xl mx-auto px-4 space-y-5">
        {content}
      </div>
    </div>
  );
};
