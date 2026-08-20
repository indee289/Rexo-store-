import React from 'react';
import { useStore } from '../../context/StoreContext';
import { UserRole } from '../../types';
import { UserCheck, Briefcase, Check, X } from 'lucide-react';

interface RoleSwitcherProps {
  isOpen: boolean;
  onClose: () => void;
}

export const RoleSwitcher: React.FC<RoleSwitcherProps> = ({ isOpen, onClose }) => {
  const { currentUser, switchRole } = useStore();

  if (!isOpen) return null;

  const roles: { role: 'creator' | 'brand'; title: string; desc: string; icon: any; color: string }[] = [
    {
      role: 'creator',
      title: 'Creator (Influencer)',
      desc: 'Browse campaigns, pitch to verified brands, submit deliverables & withdraw campaign earnings.',
      icon: UserCheck,
      color: 'bg-indigo-50 border-indigo-200 text-indigo-700',
    },
    {
      role: 'brand',
      title: 'Brand (Sponsor)',
      desc: 'Post campaign briefs, review creator pitches, hire influencers & approve escrow payouts.',
      icon: Briefcase,
      color: 'bg-purple-50 border-purple-200 text-purple-700',
    },
  ];

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="bg-white rounded-[28px] max-w-md w-full p-6 shadow-2xl border border-slate-100 space-y-5 animate-in fade-in zoom-in-95 duration-150">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-extrabold text-slate-900">Switch Marketplace Role</h2>
            <p className="text-xs text-slate-500 mt-0.5">Select active workspace perspective</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-slate-400 hover:text-slate-600 rounded-xl bg-slate-50 border border-slate-100"
          >
            <X size={18} />
          </button>
        </div>

        <div className="space-y-3">
          {roles.map((r) => {
            const Icon = r.icon;
            const isSelected = currentUser.role === r.role;
            return (
              <button
                key={r.role}
                onClick={() => {
                  switchRole(r.role);
                  onClose();
                }}
                className={`w-full text-left p-4 rounded-[20px] border transition-all flex items-start gap-3.5 ${
                  isSelected
                    ? `${r.color} ring-2 ring-indigo-500/20 shadow-xs`
                    : 'bg-white hover:bg-slate-50 border-slate-200/80 text-slate-700'
                }`}
              >
                <div className={`p-2.5 rounded-xl ${r.color} shrink-0`}>
                  <Icon size={20} />
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-bold text-slate-900">{r.title}</h3>
                    {isSelected && (
                      <span className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95">
                        <Check size={12} strokeWidth={3} />
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-slate-500 mt-1 leading-relaxed">{r.desc}</p>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};
