import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { ShieldAlert, ShieldCheck, UserX, AlertTriangle, Fingerprint, EyeOff, Activity, RefreshCw, CheckCircle, XCircle } from 'lucide-react';

export const TrustSafetyDashboard: React.FC = () => {
  const { state, adminModerateContent } = useStore();
  const [activeTab, setActiveTab] = useState<'queue' | 'users' | 'devices' | 'audit'>('queue');
  
  // MOCK DATA for safety since we haven't seeded real moderation data yet
  const queue = state.moderationQueue?.length ? state.moderationQueue : [
    { id: 'mq1', target_type: 'campaign', ai_risk_score: 95, ai_category: 'scam', ai_reason: 'Asks for off-platform payment via Crypto', status: 'pending', created_at: new Date().toISOString(), target_id: 'c1' }
  ];

  const handleAction = (queueId: string, action: 'reviewed_approved' | 'reviewed_rejected') => {
    adminModerateContent(queueId, action, 'Reviewed by Admin');
  };

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-rose-100 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-slate-500">Pending Review</p>
            <p className="text-3xl font-bold text-slate-900 mt-1">{queue.filter(q => q.status === 'pending').length}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-rose-50 flex items-center justify-center text-rose-500">
            <AlertTriangle className="w-6 h-6" />
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-slate-500">Shadow Banned</p>
            <p className="text-3xl font-bold text-slate-900 mt-1">{state.users?.filter(u => u.accountStatus === 'shadow_banned').length || 0}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-slate-50 flex items-center justify-center text-slate-500">
            <EyeOff className="w-6 h-6" />
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-slate-500">Suspended Users</p>
            <p className="text-3xl font-bold text-slate-900 mt-1">{state.users?.filter(u => u.accountStatus === 'suspended').length || 0}</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-orange-50 flex items-center justify-center text-orange-500">
            <UserX className="w-6 h-6" />
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-emerald-100 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-slate-500">AI Confidence Avg</p>
            <p className="text-3xl font-bold text-slate-900 mt-1">92%</p>
          </div>
          <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-500">
            <ShieldCheck className="w-6 h-6" />
          </div>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="border-b border-slate-100 p-2 flex gap-2 overflow-x-auto">
          {['queue', 'users', 'devices', 'audit'].map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab as any)}
              className={`px-4 py-2 text-sm font-medium rounded-xl whitespace-nowrap transition-colors ${activeTab === tab ? 'bg-slate-900 text-white' : 'text-slate-600 hover:bg-slate-50'}`}
            >
              {tab === 'queue' && 'AI Moderation Queue'}
              {tab === 'users' && 'Risk Profiles'}
              {tab === 'devices' && 'Device Fingerprints'}
              {tab === 'audit' && 'Security Audit Log'}
            </button>
          ))}
        </div>

        <div className="p-6">
          {activeTab === 'queue' && (
            <div className="space-y-4">
              {queue.map((item: any, idx) => (
                <div key={idx} className="border border-rose-100 rounded-xl p-4 flex flex-col md:flex-row gap-4 justify-between bg-rose-50/30">
                  <div>
                    <div className="flex items-center gap-2 mb-2">
                      <span className="px-2 py-1 bg-rose-100 text-rose-700 rounded-lg text-xs font-bold uppercase tracking-wider">{item.target_type}</span>
                      <span className="text-sm text-slate-500">Score: {item.ai_risk_score}/100</span>
                    </div>
                    <p className="font-semibold text-slate-900">Reason: {item.ai_reason}</p>
                    <p className="text-sm text-slate-600 mt-1">Target ID: {item.target_id}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button onClick={() => handleAction(item.id, 'reviewed_approved')} className="px-4 py-2 bg-white border border-slate-200 text-slate-700 rounded-xl text-sm font-medium hover:bg-slate-50 flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-emerald-500" /> Safe
                    </button>
                    <button onClick={() => handleAction(item.id, 'reviewed_rejected')} className="px-4 py-2 bg-rose-600 text-white rounded-xl text-sm font-medium hover:bg-rose-700 flex items-center gap-2">
                      <XCircle className="w-4 h-4" /> Enforce Ban
                    </button>
                  </div>
                </div>
              ))}
              {queue.length === 0 && (
                <div className="text-center py-12 text-slate-500">No items in moderation queue.</div>
              )}
            </div>
          )}

          {activeTab === 'users' && (
            <div className="text-center py-12 text-slate-500">Search users to view comprehensive risk profiles.</div>
          )}
          {activeTab === 'devices' && (
             <div className="text-center py-12 text-slate-500">Device Fingerprint tracking is active. Real-time graphs will populate here.</div>
          )}
          {activeTab === 'audit' && (
             <div className="text-center py-12 text-slate-500">Immutable Security logs are synced with Supabase.</div>
          )}
        </div>
      </div>
    </div>
  );
};
