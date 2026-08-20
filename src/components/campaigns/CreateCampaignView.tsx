import React, { useState, useRef } from 'react';
import { useStore } from '../../context/StoreContext';
import { NicheCategory, SocialPlatform, DeliverableType } from '../../types';
import {
  ArrowLeft,
  Sparkles,
  Upload,
  Link as LinkIcon,
  Video,
  DollarSign,
  Users,
  Calendar,
  CheckCircle2,
  FileText,
  AlertCircle,
  HelpCircle,
  Image as ImageIcon,
  Check,
  X,
  Trash2,
  Smartphone,
} from 'lucide-react';

interface CreateCampaignViewProps {
  onBack: () => void;
  onCreated: () => void;
}

const COVER_PRESETS = [
  {
    label: 'Tech & AI',
    url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80',
  },
  {
    label: 'Fashion & Lifestyle',
    url: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&auto=format&fit=crop&q=80',
  },
  {
    label: 'Music & Video',
    url: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop&q=80',
  },
  {
    label: 'Gaming & Esports',
    url: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&auto=format&fit=crop&q=80',
  },
  {
    label: 'Fitness & Health',
    url: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800&auto=format&fit=crop&q=80',
  },
];

const PLATFORM_OPTIONS: { id: SocialPlatform; name: string; color: string }[] = [
  { id: 'instagram', name: 'Instagram', color: 'from-purple-600 to-pink-500' },
  { id: 'facebook', name: 'Facebook', color: 'from-blue-600 to-indigo-600' },
  { id: 'youtube', name: 'YouTube', color: 'from-red-600 to-red-500' },
  { id: 'tiktok', name: 'TikTok', color: 'from-slate-900 to-rose-500' },
  { id: 'x', name: 'X (Twitter)', color: 'from-slate-800 to-slate-950' },
  { id: 'linkedin', name: 'LinkedIn', color: 'from-sky-700 to-blue-800' },
  { id: 'other', name: 'Other Platform', color: 'from-indigo-600 to-violet-600' },
];

const NICHE_OPTIONS: NicheCategory[] = [
  'Tech & Gadgets',
  'Fashion & Beauty',
  'Gaming & Esports',
  'Fitness & Wellness',
  'Lifestyle & Travel',
  'Business & Finance',
  'Entertainment & Comedy',
  'Food & Cooking',
];

const DELIVERABLE_OPTIONS: { id: DeliverableType; label: string; desc: string }[] = [
  { id: 'instagram_reel', label: 'Instagram Reel / Video', desc: 'Short 15-60s vertical video reel' },
  { id: 'instagram_story', label: 'Instagram Story Series', desc: '3-frame interactive story post with link' },
  { id: 'youtube_video', label: 'YouTube Shorts / Video', desc: 'Vertical Shorts or integrated video segment' },
  { id: 'tiktok_video', label: 'TikTok Video', desc: 'Viral short video with sound/hashtag' },
  { id: 'x_post', label: 'X Post / Thread', desc: 'Text, image, or video thread post' },
  { id: 'dedicated_review', label: 'Dedicated Product Review', desc: 'In-depth unboxing or review' },
];

export const CreateCampaignView: React.FC<CreateCampaignViewProps> = ({
  onBack,
  onCreated,
}) => {
  const { currentUser, createCampaign, requestNativePermission } = useStore();
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Basic Details
  const [title, setTitle] = useState('');
  const [brandName, setBrandName] = useState(
    currentUser.brandProfile?.companyName || currentUser.name || 'Rexo Brand'
  );
  const [niche, setNiche] = useState<NicheCategory>('Tech & Gadgets');
  const [platform, setPlatform] = useState<SocialPlatform>('instagram');
  const [deliverableType, setDeliverableType] = useState<DeliverableType>('instagram_reel');

  // Media & Demos
  const [coverImage, setCoverImage] = useState(COVER_PRESETS[0].url);
  const [isUploading, setIsUploading] = useState(false);
  const [sampleDemoUrl, setSampleDemoUrl] = useState('');

  // Financials & Slots
  const [payoutPerCreator, setPayoutPerCreator] = useState<number>(3500);
  const [totalSlots, setTotalSlots] = useState<number>(10);
  const [minFollowers, setMinFollowers] = useState<number>(1000);
  const [minEngagementRate, setMinEngagementRate] = useState<number>(2.0);

  // Dates & Guidelines
  const [deadline, setDeadline] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() + 14);
    return d.toISOString().split('T')[0];
  });
  const [description, setDescription] = useState('');
  const [guidelines, setGuidelines] = useState('');
  const [dosAndDontsInput, setDosAndDontsInput] = useState(
    'Tag official brand handle\nMust show product clearly in first 3 seconds\nNo explicit or copyrighted music'
  );

  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const totalBudget = payoutPerCreator * totalSlots;

  // Handle local image file selection
  const handleImageFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 10 * 1024 * 1024) {
        alert('Image file size must be less than 10MB.');
        return;
      }
      setIsUploading(true);
      const reader = new FileReader();
      reader.onload = () => {
        if (typeof reader.result === 'string') {
          setCoverImage(reader.result);
        }
        setIsUploading(false);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!title.trim() || !description.trim()) {
      alert('Please fill out campaign title and description.');
      return;
    }

    const dosAndDonts = dosAndDontsInput
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);

    const newCamp = {
      id: `camp_${Date.now()}`,
      brandId: currentUser.id,
      brandName: brandName || 'Official Brand',
      brandLogo: currentUser.avatar || 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=120&auto=format&fit=crop&q=80',
      title: title.trim(),
      description: description.trim(),
      niche,
      platform,
      deliverableType,
      payoutPerCreator: Number(payoutPerCreator),
      totalBudget,
      totalSlots: Number(totalSlots),
      filledSlots: 0,
      minFollowers: Number(minFollowers),
      minEngagementRate: Number(minEngagementRate),
      deadline,
      requirements: dosAndDonts.length > 0 ? dosAndDonts : ['Follow official brand brief guidelines'],
      status: 'active' as const,
      createdAt: new Date().toISOString(),
      coverImage,
      sampleDemoUrl: sampleDemoUrl.trim() || undefined,
      guidelines: guidelines.trim() || undefined,
      dosAndDonts,
      escrowStatus: 'held' as const,
      escrowAmount: totalBudget,
    };

    createCampaign(newCamp);
    setToastMsg('Campaign published successfully!');

    setTimeout(() => {
      onCreated();
    }, 1200);
  };

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans transition-colors">
      <div className="max-w-3xl mx-auto px-4 space-y-5">
        {/* TOP HEADER BAR */}
        <div className="flex items-center justify-between pt-1">
          <div className="flex items-center gap-3">
            <button
              onClick={onBack}
              className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 shadow-2xs hover:bg-slate-50 transition-all active:scale-95"
            >
              <ArrowLeft size={20} />
            </button>
            <div>
              <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2">
                Create Campaign <Sparkles className="w-5 h-5 text-indigo-600" />
              </h1>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                Set up cover image, target platforms, requirements and budget
              </p>
            </div>
          </div>
        </div>

        {/* FEEDBACK TOAST */}
        {toastMsg && (
          <div className="p-4 bg-emerald-500 text-white font-bold text-xs rounded-2xl flex items-center gap-2 shadow-lg animate-fade-in">
            <CheckCircle2 size={18} />
            <span>{toastMsg}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* 1. BASIC INFORMATION CARD */}
          <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 p-5 space-y-5 shadow-2xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
              <FileText size={16} className="text-indigo-600" /> Basic Campaign Information
            </h2>

            {/* Title */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                Campaign Title <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                required
                placeholder="e.g. AI Video App Launch - Instagram Reel Campaign"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-4 py-3 text-xs font-medium text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
              />
            </div>

            {/* Brand Name */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                Brand / Organizer Name
              </label>
              <input
                type="text"
                value={brandName}
                onChange={(e) => setBrandName(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-4 py-3 text-xs font-medium text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
              />
            </div>

            {/* CUSTOM UI PLATFORM SELECTOR */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-2">
                Target Platform <span className="text-rose-500">*</span>
              </label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {PLATFORM_OPTIONS.map((p) => {
                  const isSelected = platform === p.id;
                  return (
                    <button
                      key={p.id}
                      type="button"
                      onClick={() => setPlatform(p.id)}
                      className={`p-3 rounded-2xl border text-left transition-all flex items-center justify-between ${
                        isSelected
                          ? 'border-indigo-600 bg-indigo-50/70 dark:bg-indigo-950/50 text-indigo-950 dark:text-indigo-100 ring-2 ring-indigo-500/20 shadow-xs'
                          : 'border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/60 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                      }`}
                    >
                      <span className="text-xs font-extrabold">{p.name}</span>
                      {isSelected ? (
                        <span className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95">
                          <Check size={12} strokeWidth={3} />
                        </span>
                      ) : (
                        <span className="w-4 h-4 rounded-full border border-slate-300 dark:border-slate-600 shrink-0" />
                      )}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* CUSTOM UI CATEGORY CHIPS SELECTOR */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-2">
                Category (Niche) <span className="text-rose-500">*</span>
              </label>
              <div className="flex flex-wrap gap-2">
                {NICHE_OPTIONS.map((cat) => {
                  const isSelected = niche === cat;
                  return (
                    <button
                      key={cat}
                      type="button"
                      onClick={() => setNiche(cat)}
                      className={`px-3.5 py-2 rounded-2xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                        isSelected
                          ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                          : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'
                      }`}
                    >
                      {isSelected && <Check size={14} />}
                      <span>{cat}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* CUSTOM UI DELIVERABLE FORMAT CARDS */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-2">
                Deliverable Format <span className="text-rose-500">*</span>
              </label>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {DELIVERABLE_OPTIONS.map((item) => {
                  const isSelected = deliverableType === item.id;
                  return (
                    <button
                      key={item.id}
                      type="button"
                      onClick={() => setDeliverableType(item.id)}
                      className={`p-3.5 rounded-2xl border text-left transition-all ${
                        isSelected
                          ? 'border-indigo-600 bg-indigo-50/70 dark:bg-indigo-950/50 text-indigo-950 dark:text-indigo-100 ring-2 ring-indigo-500/20'
                          : 'border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/60 text-slate-700 dark:text-slate-300 hover:bg-slate-100'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-0.5">
                        <span className="text-xs font-extrabold">{item.label}</span>
                        {isSelected && (
                          <span className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95">
                            <Check size={10} strokeWidth={3} />
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">
                        {item.desc}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* 2. MEDIA UPLOAD & DEMO ASSETS CARD */}
          <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 p-5 space-y-4 shadow-2xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
              <ImageIcon size={16} className="text-indigo-600" /> Cover Image Upload & Demo Assets
            </h2>

            {/* REAL IMAGE FILE UPLOAD AREA */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-2">
                Upload Campaign Cover Image
              </label>

              {/* Hidden File Input */}
              <input
                type="file"
                ref={fileInputRef}
                accept="image/*"
                onChange={handleImageFileChange}
                className="hidden"
              />

              {/* Upload Drop Area */}
              <div
                onClick={async (e) => {
                  e.preventDefault();
                  if (requestNativePermission) {
                    const allowed = await requestNativePermission('gallery');
                    if (allowed) fileInputRef.current?.click();
                  } else {
                    fileInputRef.current?.click();
                  }
                }}
                className="cursor-pointer border-2 border-dashed border-indigo-200 dark:border-indigo-900/80 hover:border-indigo-500 bg-indigo-50/40 dark:bg-indigo-950/20 rounded-3xl p-5 text-center transition-all group"
              >
                <div className="w-12 h-12 mx-auto rounded-2xl bg-indigo-100 dark:bg-indigo-900/60 text-indigo-600 dark:text-indigo-300 flex items-center justify-center mb-2 group-hover:scale-105 transition-all">
                  <Upload size={22} />
                </div>
                <div className="text-xs font-extrabold text-slate-900 dark:text-white">
                  {isUploading ? 'Uploading Image...' : 'Click to Upload Cover Image'}
                </div>
                <p className="text-[11px] text-slate-400 mt-1 font-medium">
                  Supports PNG, JPG, WEBP photos up to 10MB
                </p>
              </div>

              {/* Uploaded Banner Live Preview */}
              {coverImage && (
                <div className="relative h-40 rounded-3xl overflow-hidden border border-slate-200 dark:border-slate-800 mt-3 shadow-xs group">
                  <img
                    src={coverImage}
                    alt="Campaign Cover"
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 via-slate-950/20 to-transparent flex items-end justify-between p-3.5">
                    <span className="text-xs font-bold text-white bg-slate-900/80 px-3 py-1 rounded-full backdrop-blur-xs flex items-center gap-1.5">
                      <CheckCircle2 size={14} className="text-emerald-400" /> Selected Banner
                    </span>

                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      className="text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 px-3 py-1.5 rounded-2xl transition-all shadow-xs"
                    >
                      Change Photo
                    </button>
                  </div>
                </div>
              )}

              {/* Artwork Preset Options */}
              <div className="pt-2">
                <span className="text-[11px] font-bold text-slate-400 block mb-1.5">
                  Or select stock preset artwork:
                </span>
                <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1">
                  {COVER_PRESETS.map((p) => (
                    <button
                      key={p.label}
                      type="button"
                      onClick={() => setCoverImage(p.url)}
                      className={`px-3 py-1.5 rounded-2xl text-[11px] font-bold transition-all shrink-0 border ${
                        coverImage === p.url
                          ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 border-transparent shadow-xs'
                          : 'bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-100'
                      }`}
                    >
                      {p.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Sample Demo Video / Asset Link */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                Sample Demo Video / Asset Link
              </label>
              <div className="relative">
                <Video className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                <input
                  type="url"
                  placeholder="https://youtube.com/watch?v=... or Google Drive link"
                  value={sampleDemoUrl}
                  onChange={(e) => setSampleDemoUrl(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl pl-10 pr-4 py-3 text-xs font-medium text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
                />
              </div>
              <p className="text-[11px] text-slate-400 mt-1">
                Optional: Add a link to a sample video, audio clip, or brand Google Drive folder for creators.
              </p>
            </div>
          </div>

          {/* 3. BUDGET, SLOTS & ELIGIBILITY */}
          <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 p-5 space-y-4 shadow-2xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
              <DollarSign size={16} className="text-emerald-500" /> Budget, Creator Slots & Requirements
            </h2>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {/* Payout per Creator */}
              <div>
                <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Payout per Creator (₹) <span className="text-rose-500">*</span>
                </label>
                <input
                  type="number"
                  required
                  min={100}
                  value={payoutPerCreator}
                  onChange={(e) => setPayoutPerCreator(Number(e.target.value))}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-4 py-3 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              {/* Total Slots */}
              <div>
                <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Total Creator Slots <span className="text-rose-500">*</span>
                </label>
                <input
                  type="number"
                  required
                  min={1}
                  value={totalSlots}
                  onChange={(e) => setTotalSlots(Number(e.target.value))}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-4 py-3 text-xs font-bold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>

            {/* Calculated Total Escrow */}
            <div className="p-3.5 bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-800/80 rounded-2xl flex items-center justify-between text-xs">
              <div>
                <span className="font-extrabold text-indigo-900 dark:text-indigo-200 block">
                  Total Campaign Budget
                </span>
                <span className="text-[11px] text-indigo-700 dark:text-indigo-300">
                  {totalSlots} creators × ₹{payoutPerCreator.toLocaleString('en-IN')}
                </span>
              </div>
              <span className="text-base font-bold text-indigo-600 dark:text-indigo-400">
                ₹{totalBudget.toLocaleString('en-IN')}
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
              {/* Min Followers */}
              <div>
                <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Min Followers
                </label>
                <input
                  type="number"
                  value={minFollowers}
                  onChange={(e) => setMinFollowers(Number(e.target.value))}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-xs text-slate-900 dark:text-white"
                />
              </div>

              {/* Min Engagement Rate */}
              <div>
                <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Min Engagement (%)
                </label>
                <input
                  type="number"
                  step="0.1"
                  value={minEngagementRate}
                  onChange={(e) => setMinEngagementRate(Number(e.target.value))}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-xs text-slate-900 dark:text-white"
                />
              </div>

              {/* Deadline */}
              <div>
                <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  Submission Deadline
                </label>
                <input
                  type="date"
                  required
                  value={deadline}
                  onChange={(e) => setDeadline(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl px-3.5 py-2.5 text-xs text-slate-900 dark:text-white"
                />
              </div>
            </div>
          </div>

          {/* 4. GUIDELINES & DESCRIPTION */}
          <div className="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/90 dark:border-slate-800/90 p-5 space-y-4 shadow-2xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white tracking-tight flex items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
              <AlertCircle size={16} className="text-amber-500" /> Campaign Description & Rules
            </h2>

            {/* Description */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                Campaign Description & Goals <span className="text-rose-500">*</span>
              </label>
              <textarea
                required
                rows={4}
                placeholder="Explain the product, core message, required music/audio, and video format expectations..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl p-4 text-xs font-medium text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
              />
            </div>

            {/* Do's and Don'ts Checklist */}
            <div>
              <label className="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                Rules & Guidelines Checklist (1 per line)
              </label>
              <textarea
                rows={3}
                placeholder="Tag official handle @brand&#10;Must include discount code in caption&#10;No competitor products in background"
                value={dosAndDontsInput}
                onChange={(e) => setDosAndDontsInput(e.target.value)}
                className="w-full bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl p-4 text-xs font-medium text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-all"
              />
            </div>
          </div>

          {/* SUBMIT BUTTON */}
          <div className="pt-2 flex items-center gap-3">
            <button
              type="button"
              onClick={onBack}
              className="flex-1 py-3.5 bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 rounded-2xl font-bold text-xs transition-all"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-2 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-extrabold text-xs shadow-md transition-all active:scale-98 flex items-center justify-center gap-2"
            >
              <Sparkles size={16} /> Publish Campaign Now
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
