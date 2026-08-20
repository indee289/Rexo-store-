import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { Campaign } from '../../types';
import { CampaignDetailsModal } from '../campaigns/CampaignDetailsModal';
import {
  Bell,
  Search,
  SlidersHorizontal,
  Bookmark,
  Instagram,
  Youtube,
  PlusCircle,
} from 'lucide-react';

interface HomeViewProps {
  onNavigateTab: (tabId: string) => void;
  onOpenPostCampaignModal: () => void;
  onSelectCampaignToApply: (campaignId: string) => void;
  onNavigateNotifications?: () => void;
}

import { PageHeader } from '../ui/PageHeader';
import { EmptyState } from '../ui/EmptyState';
import { FilterPill } from '../ui/FilterPill';

// Custom Social Icons to match the screenshot
const TikTokIcon = () => (
  <svg className="w-3.5 h-3.5 fill-slate-700" viewBox="0 0 24 24">
    <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 1 1-5.2-1.74 2.89 2.89 0 0 1 2.31-2.22V8.2a6.34 6.34 0 0 0-5.46 6.25 6.34 6.34 0 1 0 10.8-4.52V8.7a8.28 8.28 0 0 0 4.77 1.48V6.73a4.85 4.85 0 0 1-.00-.04z"/>
  </svg>
);

const XIcon = () => (
  <svg className="w-3.5 h-3.5 fill-slate-700" viewBox="0 0 24 24">
    <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
  </svg>
);

const GlobeIcon = () => (
  <svg className="w-3.5 h-3.5 stroke-slate-700 fill-none" strokeWidth="2" viewBox="0 0 24 24">
    <circle cx="12" cy="12" r="10"/>
    <path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
  </svg>
);

export const HomeView: React.FC<HomeViewProps> = ({
  onNavigateTab,
  onOpenPostCampaignModal,
  onSelectCampaignToApply,
  onNavigateNotifications,
}) => {
  const { state, currentUser, unreadNotificationsCount } = useStore();

  const isBrand = currentUser.role === 'brand';
  const myApplications = state.applications.filter((a) => a.creatorId === currentUser.id);
  const activeCampaigns = state.campaigns.filter((c) => c.status === 'active');

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [bookmarkedIds, setBookmarkedIds] = useState<string[]>([]);
  const [selectedCampaignModal, setSelectedCampaignModal] = useState<Campaign | null>(null);

  const categories = ['All', 'Music', 'Logo', 'Clipping', 'UGC', 'Tech', 'Gaming', 'Fashion'];

  const toggleBookmark = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setBookmarkedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const filteredCampaigns = activeCampaigns.filter((camp) => {
    const query = searchQuery.toLowerCase();
    const matchesSearch =
      camp.title.toLowerCase().includes(query) ||
      camp.brandName.toLowerCase().includes(query) ||
      camp.niche.toLowerCase().includes(query) ||
      camp.platform.toLowerCase().includes(query);

    const matchesCategory =
      selectedCategory === 'All' ||
      camp.niche.toLowerCase().includes(selectedCategory.toLowerCase()) ||
      (selectedCategory === 'Music' && camp.title.toLowerCase().includes('edits')) ||
      (selectedCategory === 'Clipping' && (camp.title.toLowerCase().includes('clipping') || camp.niche.toLowerCase().includes('entertainment')));

    return matchesSearch && matchesCategory;
  });

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans">
      <div className="max-w-2xl mx-auto px-4 space-y-5">
        {/* DISCOVER HEADER & NOTIFICATION */}
        <PageHeader 
          title="Discover"
          actions={
            <>
              {isBrand && (
                <button
                  onClick={onOpenPostCampaignModal}
                  className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center gap-1.5 transition-all active:scale-95 shrink-0"
                >
                  <PlusCircle size={15} /> Post Brief
                </button>
              )}
              <button
                onClick={onNavigateNotifications}
                className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 relative shadow-2xs hover:bg-slate-50 transition-all active:scale-95"
              >
                <Bell size={20} />
                {unreadNotificationsCount > 0 && (
                  <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-rose-500 rounded-full ring-2 ring-white dark:ring-slate-900" />
                )}
              </button>
            </>
          }
        />

        {/* SEARCH INPUT */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
          <input
            type="text"
            placeholder="Search for a campaign..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#EBF0F5] dark:bg-slate-900/90 border border-slate-200/60 dark:border-slate-800 rounded-2xl pl-11 pr-4 py-3 text-xs text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-rose-500/30 focus:border-rose-500 transition-all font-medium"
          />
        </div>

        {/* CATEGORY FILTER PILLS */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar scrollbar-none py-1">
          <button className="p-2.5 rounded-xl bg-[#EBF0F5] dark:bg-slate-900 border border-slate-200/60 dark:border-slate-800 text-slate-700 dark:text-slate-300 shrink-0 hover:bg-slate-200 transition-all">
            <SlidersHorizontal size={16} />
          </button>

          {categories.map((cat) => {
            const isSelected = selectedCategory === cat;
            return (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-5 py-2 rounded-full text-xs font-semibold shrink-0 transition-all ${
                  isSelected
                    ? 'bg-white dark:bg-slate-900 text-slate-900 dark:text-white border-2 border-rose-500 shadow-2xs'
                    : 'bg-[#EBF0F5] dark:bg-slate-900/80 text-slate-600 dark:text-slate-400 border border-transparent hover:bg-slate-200/80'
                }`}
              >
                {cat}
              </button>
            );
          })}
        </div>

        {/* CAMPAIGN COUNTER */}
        <div className="text-xs text-slate-500 font-medium px-1">
          {filteredCampaigns.length} of {activeCampaigns.length} campaigns
        </div>

        {/* CAMPAIGNS FEED */}
        <div className="space-y-3.5">
          {filteredCampaigns.length === 0 ? (
            <EmptyState 
              icon={<Search size={24} />}
              title="No Campaigns Match"
              description="Try searching for a different keyword or select &quot;All&quot; from categories."
            />
          ) : (
            filteredCampaigns.map((camp, idx) => {
              const myApp = myApplications.find((a) => a.campaignId === camp.id);
              const isBookmarked = bookmarkedIds.includes(camp.id);

              // Calculate mock visual percentage for campaign budget progress bar to match screenshot
              const percentage = idx === 0 ? 97 : idx === 1 ? 89 : idx === 2 ? 13 : 45;
              const formattedRate = `₹${camp.payoutPerCreator.toLocaleString()} / 1M`;
              const formattedBudget = `₹${camp.totalBudget.toLocaleString()}`;

              // Dynamic Category Tag on Image
              const categoryTag =
                camp.niche.includes('Entertainment') || idx === 0 || idx === 3
                  ? 'Clipping'
                  : camp.niche.includes('Tech')
                  ? 'Tech'
                  : 'Music';

              return (
                <div
                  key={camp.id}
                  onClick={() => setSelectedCampaignModal(camp)}
                  className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 p-4 shadow-2xs hover:shadow-md transition-all cursor-pointer relative space-y-3.5 group"
                >
                  {/* TOP ROW: LOGO, TITLE, SOCIALS, BOOKMARK */}
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-3">
                      {/* Image Thumbnail with Overlay Category Tag */}
                      <div className="relative w-14 h-14 rounded-2xl overflow-hidden shrink-0 border border-slate-100 dark:border-slate-800 shadow-2xs">
                        <img
                          src={camp.brandLogo}
                          alt={camp.brandName}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                        <div className="absolute bottom-0.5 left-0.5 bg-black/75 backdrop-blur-xs px-1.5 py-0.5 rounded-md">
                          <span className="text-[9px] font-black uppercase text-rose-400 tracking-wider block leading-none">
                            {categoryTag}
                          </span>
                        </div>
                      </div>

                      {/* Campaign Title & Social Icons */}
                      <div className="space-y-1.5">
                        <h3 className="text-sm font-extrabold text-slate-900 dark:text-white leading-snug line-clamp-2">
                          {camp.title}
                        </h3>

                        {/* Social Icons Row */}
                        <div className="flex items-center gap-2">
                          {camp.platform === 'instagram' ? (
                            <>
                              <Instagram className="w-3.5 h-3.5 text-slate-700 dark:text-slate-300" />
                              <TikTokIcon />
                              <Youtube className="w-3.5 h-3.5 text-slate-700 dark:text-slate-300" />
                              <XIcon />
                            </>
                          ) : (
                            <>
                              <GlobeIcon />
                              <TikTokIcon />
                            </>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Bookmark Icon */}
                    <button
                      onClick={(e) => toggleBookmark(camp.id, e)}
                      className="p-1 text-slate-400 hover:text-rose-500 transition-colors shrink-0"
                    >
                      <Bookmark
                        size={18}
                        className={isBookmarked ? 'fill-rose-500 text-rose-500' : ''}
                      />
                    </button>
                  </div>

                  {/* BOTTOM METRICS ROW: % / Budget & Rate / View */}
                  <div className="flex items-center justify-between text-xs pt-1 font-bold">
                    <div className="text-slate-900 dark:text-slate-100">
                      {percentage}% <span className="text-slate-400 font-normal">/ {formattedBudget}</span>
                    </div>

                    <div className="text-slate-900 dark:text-slate-100 text-right">
                      {formattedRate}
                    </div>
                  </div>

                  {/* PROGRESS BAR */}
                  <div className="w-full bg-slate-100 dark:bg-slate-800 rounded-full h-1.5 overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all duration-500 ${
                        percentage > 80
                          ? 'bg-amber-500'
                          : percentage > 30
                          ? 'bg-rose-500'
                          : 'bg-emerald-500'
                      }`}
                      style={{ width: `${percentage}%` }}
                    />
                  </div>

                  {/* APPLICATION STATUS / QUICK APPLY BUTTON IF APPLIED */}
                  {myApp && (
                    <div className="pt-1 flex justify-end">
                      <span className="px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 font-bold text-[10px] border border-emerald-200 dark:border-emerald-800 uppercase tracking-wide">
                        Status: {myApp.status}
                      </span>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>

      {selectedCampaignModal && (
        <CampaignDetailsModal
          campaign={selectedCampaignModal}
          onClose={() => setSelectedCampaignModal(null)}
        />
      )}
    </div>
  );
};
