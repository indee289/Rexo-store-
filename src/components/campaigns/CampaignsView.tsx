import { motion, AnimatePresence } from 'framer-motion';
import React, { useState, useEffect } from 'react';
import { useStore } from '../../context/StoreContext';
import { Campaign, CampaignApplication } from '../../types';
import { CreateCampaignView } from './CreateCampaignView';
import { CampaignDetailsModal } from './CampaignDetailsModal';
import { ChatModal } from '../chat/ChatModal';
import { EmptyCampaignsIllustration } from '../common/Illustrations';
import {
  Bell,
  PlusCircle,
  X,
  Send,
  ExternalLink,
  CheckCircle2,
  Clock,
  Sparkles,
  AlertCircle,
  Video,
  DollarSign,
  ShieldCheck,
  ChevronRight,
  Filter,
} from 'lucide-react';

import { PageHeader, EmptyState, FilterPill } from '../ui';

export const CampaignsView: React.FC<{
  onNavigateNotifications?: () => void;
}> = ({ onNavigateNotifications }) => {
  const {
    state,
    currentUser,
    unreadNotificationsCount,
    submitDeliverable,
  } = useStore();

  const isBrandOrAdmin = currentUser.role === 'brand' || currentUser.role === 'admin';
  const isCreator = currentUser.role === 'creator';

  // Toggle create campaign view
  const [isPostCampaignOpen, setIsPostCampaignOpen] = useState(false);

  // Active Main Tab: 'my_campaigns' vs 'explore'
  

  // Filter Pills for My Campaigns
  const [statusFilter, setStatusFilter] = useState<'explore' | 'all' | 'applied' | 'submitted' | 'approved' | 'paid' | 'rejected'>('explore');

  // Selected Campaign Details Modal
  const [selectedCampaignModal, setSelectedCampaignModal] = useState<Campaign | null>(null);

  // Submit Deliverable Modal State
  const [submitDeliverableApp, setSubmitDeliverableApp] = useState<CampaignApplication | null>(null);
  const [deliverableUrlInput, setDeliverableUrlInput] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Feedback Toast
  const [feedbackMsg, setFeedbackMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const showFeedback = (type: 'success' | 'error', text: string) => {
    setFeedbackMsg({ type, text });
    setTimeout(() => setFeedbackMsg(null), 4000);
  };

  if (isPostCampaignOpen) {
    return (
      <CreateCampaignView
        onBack={() => setIsPostCampaignOpen(false)}
        onCreated={() => setIsPostCampaignOpen(false)}
      />
    );
  }

  // User's applications
  const myApplications = state.applications.filter((a) => a.creatorId === currentUser.id);

  // Filtered Applications for "My Campaigns"
  const filteredApplications = myApplications.filter((app) => {
    if (statusFilter === 'all') return true;
    if (statusFilter === 'applied') return app.status === 'applied' || app.status === 'shortlisted';
    if (statusFilter === 'submitted') return app.status === 'submitted';
    if (statusFilter === 'approved') return app.status === 'approved';
    if (statusFilter === 'paid') return app.status === 'paid';
    if (statusFilter === 'rejected') return app.status === 'rejected';
    return true;
  });

  const handleSubmitDeliverable = (e: React.FormEvent) => {
    e.preventDefault();
    if (!submitDeliverableApp || !deliverableUrlInput.trim()) return;

    setIsSubmitting(true);
    const res = submitDeliverable(submitDeliverableApp.id, deliverableUrlInput.trim());

    setTimeout(() => {
      setIsSubmitting(false);
      if (res.success) {
        showFeedback('success', res.message);
        setSubmitDeliverableApp(null);
        setDeliverableUrlInput('');
      } else {
        showFeedback('error', res.message);
      }
    }, 400);
  };

  const getStatusBadge = (status: CampaignApplication['status']) => {
    switch (status) {
      case 'applied':
      case 'shortlisted':
        return (
          <span className="px-3 py-1 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 font-extrabold text-[10px] border border-amber-200 dark:border-amber-800 uppercase tracking-wide flex items-center gap-1">
            <Clock size={12} /> Application Applied
          </span>
        );
      case 'submitted':
        return (
          <span className="px-3 py-1 rounded-full bg-purple-50 dark:bg-purple-950/60 text-purple-800 dark:text-purple-300 font-extrabold text-[10px] border border-purple-200 dark:border-purple-800 uppercase tracking-wide flex items-center gap-1">
            <Clock size={12} /> Content Submitted (In Review)
          </span>
        );
      case 'approved':
        return (
          <span className="px-3 py-1 rounded-full bg-indigo-50 dark:bg-indigo-950/60 text-indigo-800 dark:text-indigo-300 font-extrabold text-[10px] border border-indigo-200 dark:border-indigo-800 uppercase tracking-wide flex items-center gap-1">
            <CheckCircle2 size={12} /> Content Approved (Payout Pending)
          </span>
        );
      case 'paid':
        return (
          <span className="px-3 py-1 rounded-full bg-emerald-100 dark:bg-emerald-950/80 text-emerald-800 dark:text-emerald-300 font-extrabold text-[10px] border border-emerald-300 dark:border-emerald-700 uppercase tracking-wide flex items-center gap-1">
            <CheckCircle2 size={12} /> Paid Out 🎉
          </span>
        );
      case 'rejected':
        return (
          <span className="px-3 py-1 rounded-full bg-rose-50 dark:bg-rose-950/60 text-rose-800 dark:text-rose-300 font-extrabold text-[10px] border border-rose-200 dark:border-rose-800 uppercase tracking-wide flex items-center gap-1">
            <AlertCircle size={12} /> Rejected / Revision Required
          </span>
        );
      default:
        return (
          <span className="px-3 py-1 rounded-full bg-slate-100 text-slate-700 font-extrabold text-[10px] uppercase">
            {status}
          </span>
        );
    }
  };

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans">
      <div className="max-w-2xl mx-auto px-4 space-y-5">
        {/* FEEDBACK TOAST */}
        {feedbackMsg && (
          <div
            className={`p-3.5 rounded-2xl text-xs font-bold flex items-center justify-between shadow-sm animate-fade-in ${
              feedbackMsg.type === 'success'
                ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                : 'bg-rose-50 text-rose-800 border border-rose-200'
            }`}
          >
            <span>{feedbackMsg.text}</span>
            <button onClick={() => setFeedbackMsg(null)}>
              <X size={14} />
            </button>
          </div>
        )}

        {/* HEADER & TOP ACTIONS */}
        <PageHeader 
          title="Campaigns"
          actions={
            <>
              {isBrandOrAdmin && (
                <button
                  onClick={() => setIsPostCampaignOpen(true)}
                  className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center gap-1.5 transition-all active:scale-95 shrink-0"
                >
                  <PlusCircle size={16} /> Create Brief
                </button>
              )}
              <button
                onClick={onNavigateNotifications}
                className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 relative shadow-2xs hover:bg-slate-50 transition-all active:scale-95"
              >
                <Bell size={20} />
                {unreadNotificationsCount > 0 && (
                  <span className="absolute top-1 right-1 z-10 w-2.5 h-2.5 bg-rose-500 rounded-full ring-2 ring-white dark:ring-slate-900" />
                )}
              </button>
            </>
          }
        />

        

        
        {/* ================= MAIN CONTENT & FILTERS ================= */}
        <div className="space-y-4">
            {/* STATUS FILTER PILLS */}
            <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-0.5">
              {[
                { id: 'explore', label: 'Explore All', count: state.campaigns.length },
                { id: 'all', label: 'My Campaigns', count: myApplications.length },
                { id: 'applied', label: 'Applied' },
                { id: 'submitted', label: 'In Review' },
                { id: 'approved', label: 'Approved' },
                { id: 'paid', label: 'Paid Out' },
                { id: 'rejected', label: 'Rejected' },
              ].map((pill) => (
                <FilterPill
                  key={pill.id}
                  label={pill.label}
                  isActive={statusFilter === pill.id}
                  onClick={() => setStatusFilter(pill.id as any)}
                  count={pill.count}
                />
              ))}
            </div>

            {/* MY CAMPAIGNS CONTENT (Only if not explore) */}
            {statusFilter !== "explore" && (
              <>
                {filteredApplications.length === 0 ? (
                  <EmptyState
                    icon={<EmptyCampaignsIllustration />}
                    title="No Campaigns Found"
                    description={myApplications.length === 0
                        ? 'You have not applied to any campaigns yet. Explore available briefs and start earning!'
                        : 'No campaign applications match this filter.'}
                    action={
                      myApplications.length === 0 && (
                        <button
                          onClick={() => setStatusFilter('explore')}
                          className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl transition-all"
                        >
                          Browse Active Briefs
                        </button>
                      )
                    }
                  />
                ) : (
                  <div className="space-y-3.5">
                    <AnimatePresence mode="popLayout">
                    {filteredApplications.map((app) => {
                      const campaign = state.campaigns.find((c) => c.id === app.campaignId);

                      return (
                        <motion.div
                          key={app.id}
                          layout
                          initial={{ opacity: 0, y: 10 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, scale: 0.95 }}
                          className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 p-4 shadow-2xs space-y-3.5 relative overflow-hidden group"
                        >
                          {/* STATUS BADGE */}
                          <div className="flex items-center justify-between">
                            <h3 className="text-xs font-bold text-slate-900 dark:text-white line-clamp-1">{app.campaignTitle}</h3>
                            <div className="shrink-0">{getStatusBadge(app.status)}</div>
                          </div>

                          {/* ACTION BUTTONS */}
                          <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
                            {app.status !== 'paid' && (
                              <button
                                onClick={() => {
                                  setSubmitDeliverableApp(app);
                                  setDeliverableUrlInput(app.deliverableUrl || '');
                                }}
                                className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-extrabold text-xs rounded-xl shadow-2xs flex items-center gap-1.5 transition-all active:scale-95"
                              >
                                <Send size={13} /> {app.deliverableUrl ? 'Resubmit Link' : 'Submit Link'}
                              </button>
                            )}
                          </div>
                        </motion.div>
                      );
                    })}
                    </AnimatePresence>
                  </div>
                )}
              </>
            )}
        </div>

{/* ================= TAB 2: EXPLORE ALL ACTIVE BRIEFS ================= */}
        {(statusFilter === "explore") && (
          <div className="space-y-3.5">
            {state.campaigns.length === 0 ? (
              <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 text-center border border-slate-200/80 dark:border-slate-800 text-slate-500 text-xs">
                No active campaign briefs available at this moment.
              </div>
            ) : (
              state.campaigns.map((camp) => {
                const userApp = myApplications.find((a) => a.campaignId === camp.id);

                return (
                  <div
                    key={camp.id}
                    onClick={() => setSelectedCampaignModal(camp)}
                    className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800 p-4 shadow-2xs hover:shadow-md transition-all cursor-pointer space-y-3"
                  >
                    <div className="flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <img
                          src={camp.brandLogo}
                          alt={camp.brandName}
                          className="w-12 h-12 rounded-2xl object-cover border border-slate-100 dark:border-slate-800 shrink-0 bg-slate-100"
                        />
                        <div>
                          <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-wider block">
                            {camp.niche} • {camp.platform}
                          </span>
                          <h3 className="text-xs font-bold text-slate-900 dark:text-white leading-tight line-clamp-1">
                            {camp.title}
                          </h3>
                          <span className="text-xs text-slate-500 font-medium">Brand: {camp.brandName}</span>
                        </div>
                      </div>

                      <div className="text-right shrink-0">
                        <span className="text-[10px] font-bold text-slate-400 block uppercase">PAYOUT</span>
                        <span className="text-base font-bold text-emerald-600 dark:text-emerald-400">
                          ₹{camp.payoutPerCreator?.toLocaleString('en-IN') || '3,500'}
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center justify-between pt-2 border-t border-slate-100 dark:border-slate-800 text-xs font-bold text-slate-600 dark:text-slate-400">
                      <span>Filled: {camp.filledSlots || 0} / {camp.totalSlots || 10} Slots</span>
                      {userApp ? (
                        <span className="text-emerald-600 font-extrabold uppercase text-[10px]">
                          Applied ({userApp.status})
                        </span>
                      ) : (
                        <span className="text-rose-600 hover:underline font-extrabold flex items-center gap-1 text-[11px]">
                          Apply Now <ChevronRight size={14} />
                        </span>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        )}
      </div>

      {/* SUBMIT DELIVERABLE LINK MODAL */}
      {submitDeliverableApp && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white dark:bg-slate-900 rounded-3xl p-5 max-w-md w-full space-y-4 border border-slate-200 dark:border-slate-800 shadow-2xl text-slate-900 dark:text-white">
            <div className="flex items-center justify-between pb-2 border-b border-slate-100 dark:border-slate-800">
              <div>
                <h3 className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                  <Video size={16} className="text-indigo-600" /> Submit Promotional Content Link
                </h3>
                <p className="text-[11px] text-slate-400 font-medium">
                  Campaign: {submitDeliverableApp.campaignTitle}
                </p>
              </div>
              <button
                onClick={() => setSubmitDeliverableApp(null)}
                className="p-1 rounded-full text-slate-400 hover:text-slate-600"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSubmitDeliverable} className="space-y-3.5">
              <div>
                <label className="text-xs font-extrabold text-slate-700 dark:text-slate-300 block mb-1">
                  Social Media Content Link (Reel / Story / Video URL) *
                </label>
                <input
                  type="url"
                  required
                  placeholder="https://www.instagram.com/reel/C3..."
                  value={deliverableUrlInput}
                  onChange={(e) => setDeliverableUrlInput(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-3 text-xs text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 font-medium"
                />
                <span className="text-[10px] text-slate-400 block mt-1">
                  Post your promotional video or story on Instagram/YouTube/TikTok, copy the public link and paste it here.
                </span>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setSubmitDeliverableApp(null)}
                  className="flex-1 py-2.5 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold text-xs rounded-2xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="flex-2 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-extrabold text-xs rounded-2xl shadow-md transition-all flex items-center justify-center gap-1.5"
                >
                  <Send size={14} /> {isSubmitting ? 'Submitting...' : 'Confirm Submission'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* CAMPAIGN DETAILS MODAL */}
      {selectedCampaignModal && (
        <CampaignDetailsModal
          campaign={selectedCampaignModal}
          onClose={() => setSelectedCampaignModal(null)}
        />
      )}
    </div>
  );
};
