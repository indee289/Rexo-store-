import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import {
  X,
  MapPin,
  Plus,
  Trash2,
  Edit2,
  CheckCircle2,
  Home,
  Briefcase,
  Building,
  Check,
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { ShippingAddress } from '../../types';

interface AddressBookModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AddressBookModal: React.FC<AddressBookModalProps> = ({
  isOpen,
  onClose,
}) => {
  const { currentAddresses, addAddress, updateAddress, deleteAddress, setDefaultAddress } = useStore();
  const [isAdding, setIsAdding] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  // Form State
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [street, setStreet] = useState('');
  const [landmark, setLandmark] = useState('');
  const [city, setCity] = useState('Bengaluru');
  const [state, setState] = useState('Karnataka');
  const [pincode, setPincode] = useState('');
  const [isDefault, setIsDefault] = useState(false);

  if (!isOpen) return null;

  const handleOpenAdd = () => {
    setEditingId(null);
    setFullName('');
    setPhone('');
    setStreet('');
    setLandmark('');
    setCity('Bengaluru');
    setState('Karnataka');
    setPincode('');
    setIsDefault(currentAddresses.length === 0);
    setIsAdding(true);
  };

  const handleOpenEdit = (addr: ShippingAddress) => {
    setEditingId(addr.id);
    setFullName(addr.fullName);
    setPhone(addr.phone);
    setStreet(addr.street);
    setLandmark(addr.landmark || '');
    setCity(addr.city);
    setState(addr.state);
    setPincode(addr.pincode);
    setIsDefault(!!addr.isDefault);
    setIsAdding(true);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName || !phone || !street || !pincode) return;

    if (editingId) {
      updateAddress(editingId, {
        fullName,
        phone,
        street,
        landmark,
        city,
        state,
        pincode,
        isDefault,
      });
    } else {
      addAddress({
        fullName,
        phone,
        street,
        landmark,
        city,
        state,
        pincode,
        isDefault,
      });
    }
    setIsAdding(false);
    setEditingId(null);
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
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-indigo-50 flex items-center justify-center text-indigo-600">
                <MapPin size={22} className="stroke-[2.2px]" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900">Delivery Addresses</h3>
                <p className="text-xs text-slate-500 font-medium">Manage Hardware Shipping Locations</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-slate-200 transition-colors"
            >
              <X size={16} />
            </button>
          </div>

          {/* Content */}
          <div className="overflow-y-auto py-4 space-y-4 pr-1">
            {!isAdding ? (
              <>
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-700">
                    Saved Locations ({currentAddresses.length})
                  </span>
                  <button
                    onClick={handleOpenAdd}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-indigo-600 text-white text-xs font-bold hover:bg-indigo-700 transition-colors shadow-xs"
                  >
                    <Plus size={14} />
                    <span>Add New Address</span>
                  </button>
                </div>

                {currentAddresses.length === 0 ? (
                  <div className="p-8 text-center bg-slate-50 rounded-2xl border border-slate-100 space-y-2">
                    <MapPin size={28} className="text-slate-400 mx-auto" />
                    <p className="text-xs font-bold text-slate-700">No Addresses Saved</p>
                    <p className="text-[11px] text-slate-500">
                      Add a shipping address for physical equipment orders and studio gear.
                    </p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {currentAddresses.map((addr) => (
                      <div
                        key={addr.id}
                        className={`p-4 rounded-2xl border transition-all ${
                          addr.isDefault
                            ? 'border-indigo-600 bg-indigo-50/20 shadow-xs'
                            : 'border-slate-200 bg-white hover:border-slate-300'
                        }`}
                      >
                        <div className="flex items-start justify-between">
                          <div>
                            <div className="flex items-center gap-2">
                              <h5 className="text-xs font-bold text-slate-900">{addr.fullName}</h5>
                              {addr.isDefault && (
                                <span className="text-[10px] font-bold text-indigo-700 bg-indigo-100 px-2 py-0.5 rounded-md">
                                  Default
                                </span>
                              )}
                            </div>
                            <p className="text-xs text-slate-600 mt-1 font-medium leading-relaxed">
                              {addr.street}
                              {addr.landmark && `, Landmark: ${addr.landmark}`}
                            </p>
                            <p className="text-xs text-slate-500 font-medium">
                              {addr.city}, {addr.state} - <span className="font-bold text-slate-700">{addr.pincode}</span>
                            </p>
                            <p className="text-xs text-slate-600 font-medium mt-1">
                              Phone: <span className="font-bold text-slate-800">{addr.phone}</span>
                            </p>
                          </div>

                          <div className="flex items-center gap-1.5 shrink-0">
                            <button
                              onClick={() => handleOpenEdit(addr)}
                              className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors"
                              title="Edit Address"
                            >
                              <Edit2 size={14} />
                            </button>
                            <button
                              onClick={() => deleteAddress(addr.id)}
                              className="p-2 rounded-xl bg-slate-100 hover:bg-rose-50 text-slate-400 hover:text-rose-600 transition-colors"
                              title="Delete Address"
                            >
                              <Trash2 size={14} />
                            </button>
                          </div>
                        </div>

                        {!addr.isDefault && (
                          <button
                            onClick={() => setDefaultAddress(addr.id)}
                            className="mt-3 text-xs font-bold text-indigo-600 hover:text-indigo-800 flex items-center gap-1 transition-colors"
                          >
                            <span>Set as Default Delivery Address</span>
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </>
            ) : (
              <form onSubmit={handleSave} className="space-y-3.5">
                <div className="flex items-center justify-between pb-1">
                  <h4 className="text-xs font-bold text-slate-900 uppercase tracking-wider">
                    {editingId ? 'Edit Address' : 'New Shipping Address'}
                  </h4>
                  <button
                    type="button"
                    onClick={() => setIsAdding(false)}
                    className="text-xs text-slate-500 hover:text-slate-800 font-medium"
                  >
                    Cancel
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">Full Name *</label>
                    <input
                      type="text"
                      required
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      placeholder="Receiver Name"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">Contact Phone *</label>
                    <input
                      type="tel"
                      required
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="+91 98765 43210"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                    />
                  </div>
                </div>

                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Street Address, Flat / House No. *</label>
                  <input
                    type="text"
                    required
                    value={street}
                    onChange={(e) => setStreet(e.target.value)}
                    placeholder="Flat 402, Sunshine Heights, 12th Main"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                  />
                </div>

                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Landmark (Optional)</label>
                  <input
                    type="text"
                    value={landmark}
                    onChange={(e) => setLandmark(e.target.value)}
                    placeholder="Near Metro Station / Opposite Park"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                  />
                </div>

                <div className="grid grid-cols-3 gap-2.5">
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">City *</label>
                    <input
                      type="text"
                      required
                      value={city}
                      onChange={(e) => setCity(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">State *</label>
                    <input
                      type="text"
                      required
                      value={state}
                      onChange={(e) => setState(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">Pincode *</label>
                    <input
                      type="text"
                      required
                      maxLength={6}
                      value={pincode}
                      onChange={(e) => setPincode(e.target.value)}
                      placeholder="560038"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                    />
                  </div>
                </div>

                <label className="flex items-center gap-2 pt-1 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isDefault}
                    onChange={(e) => setIsDefault(e.target.checked)}
                    className="w-4 h-4 rounded text-indigo-600 border-slate-300 focus:ring-indigo-500"
                  />
                  <span className="text-xs font-semibold text-slate-700">Make this my default shipping address</span>
                </label>

                <div className="pt-2">
                  <button
                    type="submit"
                    className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
                  >
                    {editingId ? 'Update Address' : 'Save Address'}
                  </button>
                </div>
              </form>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
