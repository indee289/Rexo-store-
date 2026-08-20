import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { Campaign } from '../../types';
import {
  X,
  Sparkles,
  DollarSign,
  Users,
  Calendar,
  CheckCircle2,
  AlertCircle,
  ExternalLink,
  Send,
  Video,
  ShieldCheck,
  Instagram,
  Youtube,
  Clock,
  ArrowRight,
  Check,
} from 'lucide-react';

interface CampaignDetailsModalProps {
  campaign: Campaign;
  onClose: () => void;
}

export const CampaignDetailsModal: React.FC<CampaignDetailsModalProps> = ({
  campaign,
  onClose,
}) => {
  const { state, currentUser, applyToCampaign } = useStore();

  const isCreator = currentUser.role === 'creator';
  const myApp = state.applications.find(
    (a) => a.campaignId === campaign.id && a.creatorId === currentUser.id
  );

  const [showApplyForm, setShowApplyForm] = useState(false);
  const [pitch, setPitch] = useState(
    `Hey ${campaign.brandName}! I love this product concept and would create an engaging, high-retention video tailored for my audience.`
  );
  const [requestedFee, setRequestedFee] = useState(campaign.payoutPerCreator || 3500);
  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleApplySubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!pitch.trim()) {
      alert('Please enter a short pitch for your application.');
      return;
    }

    setIsSubmitting(true);
    applyToCampaign(campaign.id, pitch.trim(), Number(requestedFee));

    setTimeout(() => {
      setIsSubmitting(false);
      setShowApplyForm(false);
      setToastMsg('Application submitted successfully!');
      setTimeout(() => setToastMsg(null), 4000);
    }, 600);
  };

  const percentageFilled = Math.min(
    100,
    Math.round((campaign.filledSlots / Math.max(1, campaign.totalSlots)) * 100)
  );

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-3 sm:p-4 overflow-y-auto animate-fade-in">
      <div className="bg-white dark:bg-slate-900 rounded-3xl max-w-xl w-full border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden my-auto max-h-[92vh] flex flex-col relative text-slate-900 dark:text-slate-100 font-sans">
        
        {/* TOP COVER BANNER & CLOSE */}
        <div className="relative h-48 sm:h-56 shrink-0 bg-slate-900 overflow-hidden">
          <img
            src={
              campaign.coverImage ||
              'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80'
            }
            alt={campaign.title}
            className="w-full h-full object-cover opacity-90"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/40 to-transparent" />

          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute top-3 right-3 p-2 rounded-full bg-slate-950/60 text-white hover:bg-slate-900 backdrop-blur-md transition-all active:scale-95"
          >
            <X size={18} />
          </button>

          {/* Category & Platform Badges */}
          <div className="absolute top-3 left-3 flex items-center gap-1.5">
            <span className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95">
              {campaign.niche}
            </span>
            <span className="px-3 py-1 rounded-full bg-slate-900/80 text-white text-[10px] font-bold uppercase tracking-wider backdrop-blur-md flex items-center gap-1">
              {campaign.platform}
            </span>
          </div>

          {/* Brand Logo & Title Overlay */}
          <div className="absolute bottom-4 left-4 right-4 flex items-end gap-3">
            <div className="w-14 h-14 rounded-2xl overflow-hidden border-2 border-white dark:border-slate-800 shadow-md shrink-0 bg-white">
              <img
                src={
                  campaign.brandLogo ||
                  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=120&auto=format&fit=crop&q=80'
                }
                alt={campaign.brandName}
                className="w-full h-full object-cover"
              />
            </div>
            <div className="flex-1 min-w-0">
              <span className="text-[11px] font-bold text-indigo-300 flex items-center gap-1">
                {campaign.brandName} <ShieldCheck size={13} className="text-indigo-400 inline" />
              </span>
              <h2 className="text-base sm:text-lg font-black text-white leading-tight line-clamp-2">
                {campaign.title}
              </h2>
            </div>
          </div>
        </div>

        {/* SCROLLABLE BODY DETAILS */}
        <div className="p-4 sm:p-5 overflow-y-auto space-y-4 flex-1 text-xs">
          {/* TOAST MESSAGE */}
          {toastMsg && (
            <div className="p-3 bg-emerald-500 text-white font-bold rounded-2xl flex items-center gap-2 shadow-lg animate-fade-in">
              <CheckCircle2 size={16} />
              <span>{toastMsg}</span>
            </div>
          )}

          {/* KEY STATS ROW */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
            {/* Payout */}
            <div className="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200/80 dark:border-slate-700/80">
              <span className="text-[10px] font-bold text-slate-400 block mb-0.5">PAYOUT PER CREATOR</span>
              <span className="text-base font-black text-emerald-600 dark:text-emerald-400">
                ₹{campaign.payoutPerCreator?.toLocaleString('en-IN') || '3,500'}
              </span>
            </div>

            {/* Total Budget */}
            <div className="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200/80 dark:border-slate-700/80">
              <span className="text-[10px] font-bold text-slate-400 block mb-0.5">TOTAL CAMPAIGN POOL</span>
              <span className="text-base font-black text-indigo-600 dark:text-indigo-400">
                ₹{campaign.totalBudget?.toLocaleString('en-IN') || '35,000'}
              </span>
            </div>

            {/* Slots */}
            <div className="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200/80 dark:border-slate-700/80 col-span-2 sm:col-span-1">
              <span className="text-[10px] font-bold text-slate-400 block mb-0.5">SLOTS FILLED</span>
              <div className="flex items-center justify-between">
                <span className="text-xs font-extrabold text-slate-900 dark:text-white">
                  {campaign.filledSlots || 0} / {campaign.totalSlots || 10} Slots
                </span>
                <span className="text-[10px] text-indigo-600 font-extrabold">{percentageFilled}%</span>
              </div>
              <div className="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-1.5 mt-1.5 overflow-hidden">
                <div
                  className="bg-indigo-600 h-full rounded-full transition-all"
                  style={{ width: `${percentageFilled}%` }}
                />
              </div>
            </div>
          </div>

          {/* FORMAT & REQUIREMENTS INFO */}
          <div className="p-3.5 bg-indigo-50/70 dark:bg-indigo-950/40 border border-indigo-100 dark:border-indigo-900/60 rounded-2xl grid grid-cols-2 gap-3 text-slate-800 dark:text-indigo-200 font-medium">
            <div>
              <span className="text-[10px] font-bold text-slate-400 block">DELIVERABLE FORMAT</span>
              <span className="font-extrabold text-xs capitalize text-slate-900 dark:text-white">
                {campaign.deliverableType ? campaign.deliverableType.replace('_', ' ') : 'Instagram Reel'}
              </span>
            </div>
            <div>
              <span className="text-[10px] font-bold text-slate-400 block">SUBMISSION DEADLINE</span>
              <span className="font-extrabold text-xs text-slate-900 dark:text-white flex items-center gap-1">
                <Calendar size={13} className="text-indigo-600 inline" />
                {campaign.deadline || '14 Days'}
              </span>
            </div>
            <div>
              <span className="text-[10px] font-bold text-slate-400 block">MIN FOLLOWERS</span>
              <span className="font-bold text-xs text-slate-900 dark:text-white">
                {campaign.minFollowers ? campaign.minFollowers.toLocaleString() : '1,000'} Followers
              </span>
            </div>
            <div>
              <span className="text-[10px] font-bold text-slate-400 block">MIN ENGAGEMENT</span>
              <span className="font-bold text-xs text-slate-900 dark:text-white">
                {campaign.minEngagementRate || 2.0}% Rate
              </span>
            </div>
          </div>

          {/* DESCRIPTION */}
          <div>
            <h3 className="text-xs font-extrabold text-slate-900 dark:text-white uppercase tracking-wider mb-1.5">
              Campaign Brief & Goals
            </h3>
            <p className="text-slate-600 dark:text-slate-300 leading-relaxed font-medium">
              {campaign.description}
            </p>
          </div>

          {/* SAMPLE DEMO VIDEO / LINK */}
          {campaign.sampleDemoUrl && (
            <div className="p-3 bg-slate-50 dark:bg-slate-800/80 rounded-2xl border border-slate-200/80 dark:border-slate-700/80 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Video size={16} className="text-indigo-600" />
                <span className="font-bold text-slate-900 dark:text-white">Sample Demo Asset Link</span>
              </div>
              <a
                href={campaign.sampleDemoUrl}
                target="_blank"
                rel="noreferrer"
                className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                View Asset <ExternalLink size={12} />
              </a>
            </div>
          )}

          {/* RULES / GUIDELINES */}
          {campaign.requirements && campaign.requirements.length > 0 && (
            <div>
              <h3 className="text-xs font-extrabold text-slate-900 dark:text-white uppercase tracking-wider mb-2">
                Rules & Do's / Don'ts
              </h3>
              <div className="space-y-1.5">
                {campaign.requirements.map((req, idx) => (
                  <div key={idx} className="flex items-start gap-2 text-slate-700 dark:text-slate-300">
                    <CheckCircle2 size={14} className="text-emerald-500 shrink-0 mt-0.5" />
                    <span className="font-medium">{req}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* APPLICATION FORM MODAL (IF CREATOR CLICKS APPLY) */}
          {showApplyForm && isCreator && !myApp && (
            <div className="p-4 bg-indigo-50/90 dark:bg-slate-800 border-2 border-indigo-500 rounded-2xl space-y-3 animate-fade-in">
              <div className="flex items-center justify-between">
                <h4 className="font-extrabold text-xs text-indigo-950 dark:text-indigo-100 flex items-center gap-1.5">
                  <Sparkles size={15} className="text-indigo-600" /> Submit Campaign Application
                </h4>
                <button
                  type="button"
                  onClick={() => setShowApplyForm(false)}
                  className="text-slate-400 hover:text-slate-600"
                >
                  <X size={16} />
                </button>
              </div>

              <form onSubmit={handleApplySubmit} className="space-y-3">
                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    Your Pitch / Why You are a Great Fit *
                  </label>
                  <textarea
                    required
                    rows={3}
                    value={pitch}
                    onChange={(e) => setPitch(e.target.value)}
                    className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl p-2.5 text-xs text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    Proposed Payout Fee (₹)
                  </label>
                  <input
                    type="number"
                    required
                    value={requestedFee}
                    onChange={(e) => setRequestedFee(Number(e.target.value))}
                    className="w-full bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 dark:text-white"
                  />
                </div>

                <div className="flex items-center gap-2 pt-1">
                  <button
                    type="button"
                    onClick={() => setShowApplyForm(false)}
                    className="flex-1 py-2 bg-slate-200 dark:bg-slate-700 text-slate-800 dark:text-slate-200 font-bold rounded-xl"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
                  >
                    <Send size={14} /> {isSubmitting ? 'Submitting...' : 'Confirm Application'}
                  </button>
                </div>
              </form>
            </div>
          )}
        </div>

        {/* BOTTOM ACTION BAR */}
        <div className="p-3.5 sm:p-4 bg-slate-50 dark:bg-slate-900/90 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between gap-3 shrink-0">
          <div>
            <span className="text-[10px] text-slate-400 font-bold block uppercase">CREATOR PAYOUT</span>
            <span className="text-base font-black text-emerald-600 dark:text-emerald-400">
              ₹{campaign.payoutPerCreator?.toLocaleString('en-IN') || '3,500'}
            </span>
          </div>

          {isCreator ? (
            myApp ? (
              <div className="px-4 py-2.5 bg-emerald-50 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800 rounded-2xl font-extrabold text-xs flex items-center gap-1.5">
                <CheckCircle2 size={16} /> Applied (Status: {myApp.status.toUpperCase()})
              </div>
            ) : !showApplyForm ? (
              <button
                type="button"
                onClick={() => setShowApplyForm(true)}
                className="px-6 py-3 bg-rose-600 hover:bg-rose-700 text-white font-extrabold text-xs rounded-2xl shadow-md transition-all active:scale-95 flex items-center gap-2"
              >
                Apply for Campaign <ArrowRight size={16} />
              </button>
            ) : null
          ) : (
            <div className="px-4 py-2 bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold text-xs rounded-2xl">
              Brand View ({campaign.filledSlots || 0} Applicants)
            </div>
          )}
        </div>

      </div>
    </div>
  );
};
