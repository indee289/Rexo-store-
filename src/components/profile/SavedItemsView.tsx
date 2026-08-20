import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import {
  Bookmark,
  Trash2,
  ShoppingCart,
  Star,
  Sparkles,
  ArrowRight,
  Package,
  Layers,
  GraduationCap,
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface SavedItemsViewProps {
  onNavigateToExplore?: () => void;
  onOpenProduct?: (type: 'course' | 'digital' | 'physical', id: string) => void;
}

export const SavedItemsView: React.FC<SavedItemsViewProps> = ({
  onNavigateToExplore,
  onOpenProduct,
}) => {
  const { currentSavedItems, toggleSavedItem, addToCart } = useStore();
  const [filter, setFilter] = useState<'all' | 'course' | 'digital' | 'physical'>('all');

  const filteredItems = currentSavedItems.filter(
    (item) => filter === 'all' || item.itemType === filter
  );

  const handleMoveToCart = (item: typeof currentSavedItems[0]) => {
    addToCart({
      referenceId: item.referenceId,
      itemType: item.itemType,
      title: item.title,
      price: item.price,
      quantity: 1,
      image: item.image,
      category: item.category,
    });
    toggleSavedItem(item);
  };

  return (
    <div className="space-y-4">
      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1">
        {(['all', 'course', 'digital', 'physical'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold capitalize whitespace-nowrap transition-all ${
              filter === f
                ? 'bg-slate-900 text-white shadow-xs'
                : 'bg-white border border-slate-200 text-slate-600 hover:border-slate-300'
            }`}
          >
            {f === 'all' ? 'All Saved' : f === 'course' ? 'Courses' : f === 'digital' ? 'Digital' : 'Equipment'}
          </button>
        ))}
      </div>

      {filteredItems.length === 0 ? (
        <div className="bg-white rounded-3xl p-8 text-center border border-slate-100 shadow-xs space-y-3">
          <div className="w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400 mx-auto">
            <Bookmark size={26} />
          </div>
          <h4 className="text-sm font-bold text-slate-800">Your Wishlist is Empty</h4>
          <p className="text-xs text-slate-500 max-w-xs mx-auto">
            Save courses, AI prompt libraries, and studio hardware to review and purchase later.
          </p>
          {onNavigateToExplore && (
            <button
              onClick={onNavigateToExplore}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 text-white text-xs font-bold hover:bg-slate-800 transition-colors"
            >
              <span>Explore Marketplace</span>
              <ArrowRight size={14} />
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          <AnimatePresence>
            {filteredItems.map((item) => (
              <motion.div
                key={item.id}
                layout
                initial={{ opacity: 0, scale: 0.98 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                className="bg-white rounded-2xl p-3.5 border border-slate-100 shadow-xs flex items-center gap-3.5 hover:border-slate-200 transition-all"
              >
                {/* Thumbnail */}
                <div
                  onClick={() => onOpenProduct?.(item.itemType, item.referenceId)}
                  className="w-18 h-18 rounded-xl bg-slate-100 overflow-hidden relative shrink-0 cursor-pointer"
                >
                  <img
                    src={item.image}
                    alt={item.title}
                    referrerPolicy="no-referrer"
                    className="w-full h-full object-cover"
                  />
                  <span className="absolute bottom-1 left-1 px-1.5 py-0.5 rounded bg-black/60 backdrop-blur-xs text-[9px] font-bold text-white uppercase">
                    {item.itemType}
                  </span>
                </div>

                {/* Details */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded-md">
                      {item.category}
                    </span>
                    <div className="flex items-center text-amber-500 text-[11px] font-semibold gap-0.5">
                      <Star size={12} className="fill-amber-400" />
                      <span>{item.rating}</span>
                    </div>
                  </div>

                  <h5
                    onClick={() => onOpenProduct?.(item.itemType, item.referenceId)}
                    className="text-xs font-bold text-slate-900 truncate mt-1 cursor-pointer hover:text-indigo-600"
                  >
                    {item.title}
                  </h5>

                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-sm font-bold text-slate-900">₹{item.price}</span>
                    {item.originalPrice && (
                      <span className="text-xs text-slate-400 line-through font-medium">
                        ₹{item.originalPrice}
                      </span>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex flex-col gap-2 shrink-0">
                  <button
                    onClick={() => handleMoveToCart(item)}
                    className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
                    title="Move to Cart"
                  >
                    <ShoppingCart size={15} />
                  </button>
                  <button
                    onClick={() => toggleSavedItem(item)}
                    className="p-2.5 rounded-xl bg-slate-100 hover:bg-rose-50 text-slate-400 hover:text-rose-600 active:scale-95 transition-all flex items-center justify-center"
                    title="Remove"
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      )}
    </div>
  );
};
