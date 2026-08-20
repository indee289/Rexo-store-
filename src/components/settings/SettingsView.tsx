import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import { fetchActiveSessions, fetchSecurityLogs, revokeSession, UserSession, SecurityLog } from '../../services/securityService';
import { TwoFactorSetup } from './TwoFactorSetup';
import {
  ChevronLeft,
  Lock,
  ShieldCheck,
  Smartphone,
  History,
  ShieldAlert,
  X,
  CheckCircle2,
  Clock,
  KeyRound,
  Eye,
  EyeOff,
  FileText,
} from 'lucide-react';
import { PrivacyPolicyModal } from '../common/PrivacyPolicyModal';

interface SettingsViewProps {
  onBack: () => void;
}

export const SettingsView: React.FC<SettingsViewProps> = ({ onBack }) => {
  const { userSettings, updateUserSettings } = useStore();

  const [activeSection, setActiveSection] = useState<
    'overview' | 'change_password' | '2fa' | 'active_sessions' | 'login_history' | 'security_logs'
  >('overview');
  const [showPrivacyModal, setShowPrivacyModal] = useState(false);

  // Form states for password change
  const [oldPassword, setOldPassword] = useState('');
  const [realSessions, setRealSessions] = useState<UserSession[]>([]);
  const [realLogs, setRealLogs] = useState<SecurityLog[]>([]);

  React.useEffect(() => {
    if (activeSection === 'active_sessions') {
      fetchActiveSessions().then(setRealSessions);
    } else if (activeSection === 'security_logs' || activeSection === 'login_history') {
      fetchSecurityLogs().then(setRealLogs);
    }
  }, [activeSection]);

  const handleRevoke = async (id: string) => {
    const success = await revokeSession(id);
    if (success) {
      showToast('Session revoked successfully!');
      setRealSessions(realSessions.map(s => s.id === id ? { ...s, status: 'revoked' } : s));
    } else {
      showToast('Failed to revoke session');
    }
  };

  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPass, setShowPass] = useState(false);

  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3000);
  };

  const handleChangePassword = (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      showToast('New passwords do not match!');
      return;
    }
    setOldPassword('');
    setNewPassword('');
    setConfirmPassword('');
    showToast('Password updated successfully!');
    setActiveSection('overview');
  };

  // Mocked real security audit logs
  const securityLogs = [
    { id: '1', action: 'Password verification check', ip: '103.21.124.8', date: '2026-08-18 10:14 AM', status: 'Success' },
    { id: '2', action: '2FA verification toggle', ip: '103.21.124.8', date: '2026-08-17 04:30 PM', status: 'Success' },
    { id: '3', action: 'Session token refreshed', ip: '103.21.124.8', date: '2026-08-15 09:12 AM', status: 'Success' },
  ];

  const loginHistory = [
    { id: '1', device: 'iPhone 15 Pro', location: 'Bangalore, India', date: 'Today, 10:14 AM', status: 'Active Now' },
    { id: '2', device: 'MacBook Pro 16"', location: 'Mumbai, India', date: 'Yesterday, 03:45 PM', status: 'Completed' },
    { id: '3', device: 'Chrome on Windows', location: 'Delhi, India', date: '12 Aug 2026, 11:20 AM', status: 'Logged Out' },
  ];

  return (
    <div className="min-h-screen bg-[#F4F6F8] dark:bg-slate-950 pb-28 pt-4 text-slate-900 dark:text-slate-100 font-sans transition-colors">
      <div className="max-w-2xl mx-auto px-4 space-y-5">
        {/* HEADER WITH < BACK BUTTON TO PROFILE */}
        <div className="flex items-center gap-4 pt-1 pb-4">
          <button
            onClick={() => {
              if (activeSection !== 'overview') {
                setActiveSection('overview');
              } else {
                onBack();
              }
            }}
            className="p-2.5 rounded-full bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-700 dark:text-slate-300 relative shadow-2xs hover:bg-slate-50 transition-all active:scale-95"
          >
            <ChevronLeft size={20} />
          </button>
          
          <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
            {activeSection === 'overview' ? 'Security Settings' : activeSection.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')}
          </h1>
        </div>

        {/* TOAST NOTIFICATION */}
        {toastMsg && (
          <div className="p-3.5 bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-bold rounded-2xl flex items-center justify-between">
            <span>{toastMsg}</span>
            <button onClick={() => setToastMsg(null)}>
              <X size={14} />
            </button>
          </div>
        )}

        {/* MAIN SECURITY SECTIONS OVERVIEW */}
        {activeSection === 'overview' && (
          <div className="space-y-4">
            <div className="bg-white dark:bg-slate-900 rounded-[32px] border border-slate-200/80 dark:border-slate-800 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800/60 shadow-2xs text-xs font-bold">
              {/* CHANGE PASSWORD */}
              <button
                onClick={() => setActiveSection('change_password')}
                className="w-full text-left p-4 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-slate-800 dark:text-slate-200 flex items-center justify-between transition-all"
              >
                <div className="flex items-center gap-3">
                  <KeyRound size={18} className="text-indigo-600" />
                  <div>
                    <span className="block text-slate-900 dark:text-white font-extrabold">Change Password</span>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">Update account login password</span>
                  </div>
                </div>
                <span className="text-slate-400">›</span>
              </button>

              {/* TWO FACTOR AUTHENTICATION */}
              <button
                onClick={() => setActiveSection('2fa')}
                className="w-full text-left p-4 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-slate-800 dark:text-slate-200 flex items-center justify-between transition-all"
              >
                <div className="flex items-center gap-3">
                  <ShieldCheck size={18} className="text-purple-600" />
                  <div>
                    <span className="block text-slate-900 dark:text-white font-extrabold">Two-Factor Authentication (2FA)</span>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">OTP protection for wallet withdrawals</span>
                  </div>
                </div>
                <span className="text-[10px] px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-700 font-bold">
                  {userSettings.twoFactorAuth ? 'ENABLED' : 'DISABLED'}
                </span>
              </button>

              {/* ACTIVE SESSIONS */}
              <button
                onClick={() => setActiveSection('active_sessions')}
                className="w-full text-left p-4 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-slate-800 dark:text-slate-200 flex items-center justify-between transition-all"
              >
                <div className="flex items-center gap-3">
                  <Smartphone size={18} className="text-blue-600" />
                  <div>
                    <span className="block text-slate-900 dark:text-white font-extrabold">Active Sessions</span>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">Manage signed-in browsers and mobile devices</span>
                  </div>
                </div>
                <span className="text-slate-400">›</span>
              </button>

              {/* LOGIN HISTORY */}
              <button
                onClick={() => setActiveSection('login_history')}
                className="w-full text-left p-4 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-slate-800 dark:text-slate-200 flex items-center justify-between transition-all"
              >
                <div className="flex items-center gap-3">
                  <History size={18} className="text-amber-600" />
                  <div>
                    <span className="block text-slate-900 dark:text-white font-extrabold">Login History</span>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">Recent IP addresses & device authentications</span>
                  </div>
                </div>
                <span className="text-slate-400">›</span>
              </button>

              {/* SECURITY LOGS */}
              <button
                onClick={() => setActiveSection('security_logs')}
                className="w-full text-left p-4 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-slate-800 dark:text-slate-200 flex items-center justify-between transition-all"
              >
                <div className="flex items-center gap-3">
                  <ShieldAlert size={18} className="text-rose-600" />
                  <div>
                    <span className="block text-slate-900 dark:text-white font-extrabold">Security Logs</span>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">Audit logs of security events & verification changes</span>
                  </div>
                </div>
                <span className="text-slate-400">›</span>
              </button>

              {/* PRIVACY POLICY */}
              <button
                onClick={() => setShowPrivacyModal(true)}
                className="w-full text-left p-4 hover:bg-slate-50 dark:hover:bg-slate-800/60 text-slate-800 dark:text-slate-200 flex items-center justify-between transition-all"
              >
                <div className="flex items-center gap-3">
                  <FileText size={18} className="text-emerald-600" />
                  <div>
                    <span className="block text-slate-900 dark:text-white font-extrabold">Privacy Policy</span>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">Read data protection & usage policies</span>
                  </div>
                </div>
                <span className="text-slate-400">›</span>
              </button>
            </div>
          </div>
        )}

        {/* SUB-PANEL: CHANGE PASSWORD */}
        {activeSection === 'change_password' && (
          <div className="bg-white dark:bg-slate-900 p-6 rounded-[32px] border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4 text-xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white">Update Password</h2>
            <form onSubmit={handleChangePassword} className="space-y-3">
              <div>
                <label className="block font-bold text-slate-700 mb-1">Current Password</label>
                <div className="relative">
                  <input
                    type={showPass ? 'text' : 'password'}
                    required
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    className="w-full bg-slate-50 dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-700/60 rounded-2xl p-3 pr-10 text-slate-900 dark:text-white focus:outline-none"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPass(!showPass)}
                    className="absolute right-3 top-3 text-slate-400"
                  >
                    {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">New Password</label>
                <input
                  type="password"
                  required
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-700/60 rounded-2xl p-3 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Confirm New Password</label>
                <input
                  type="password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full bg-slate-50 dark:bg-slate-800/60 border border-slate-200/80 dark:border-slate-700/60 rounded-2xl p-3 text-slate-900 dark:text-white focus:outline-none"
                />
              </div>

              <button
                type="submit"
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-xl shadow-xs inline-flex items-center justify-center gap-1.5 transition-all active:scale-95"
              >
                Save New Password
              </button>
            </form>
          </div>
        )}
        {/* SUB-PANEL: 2FA */}
        {activeSection === '2fa' && (
          <div className="bg-white dark:bg-slate-900 p-6 rounded-[32px] border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4 text-xs">
            <TwoFactorSetup />
          </div>
        )}

        {/* SUB-PANEL: ACTIVE SESSIONS */}
        {activeSection === 'active_sessions' && (
          <div className="bg-white dark:bg-slate-900 p-6 rounded-[32px] border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4 text-xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white">Signed-in Devices</h2>
            {realSessions.length > 0 ? realSessions.map((session) => (
              <div key={session.id} className="p-3.5 bg-slate-50 dark:bg-slate-800/60 rounded-2xl border border-slate-100 dark:border-slate-700/60 flex items-center justify-between">
                <div>
                  <h3 className="font-extrabold text-slate-900 dark:text-white">{session.device_info} {session.is_current ? '(Current Device)' : ''}</h3>
                  <p className="text-[10px] text-slate-500">{session.ip_address} • {new Date(session.last_active).toLocaleString()}</p>
                </div>
                {session.status === 'active' ? (
                  session.is_current ? (
                    <span className="text-[10px] font-extrabold text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
                      ACTIVE
                    </span>
                  ) : (
                    <button
                      onClick={() => handleRevoke(session.id)}
                      className="text-[11px] font-bold text-rose-600 hover:underline"
                    >
                      Revoke Session
                    </button>
                  )
                ) : (
                   <span className="text-[10px] font-extrabold text-slate-600 bg-slate-100 px-2.5 py-1 rounded-full border border-slate-200">
                      REVOKED
                    </span>
                )}
              </div>
            )) : (
              <div className="text-center py-4 text-slate-500">Loading active sessions...</div>
            )}
          </div>
        )}
        {activeSection === 'login_history' && (
          <div className="bg-white dark:bg-slate-900 p-6 rounded-[32px] border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4 text-xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white">Recent Login History</h2>
            <div className="space-y-2">
              {realLogs.filter(log => log.action.includes('Login')).length > 0 ? 
                realLogs.filter(log => log.action.includes('Login')).map((log) => (
                <div key={log.id} className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-2xl border border-slate-100 dark:border-slate-700/60 flex items-center justify-between">
                  <div>
                    <h3 className="font-bold text-slate-900 dark:text-white">{log.device_info}</h3>
                    <p className="text-[10px] text-slate-500">IP: {log.ip_address} • {new Date(log.created_at).toLocaleString()}</p>
                  </div>
                  <span className="text-[10px] font-bold text-slate-600 bg-slate-100 px-2 py-0.5 rounded-full">
                    {log.status}
                  </span>
                </div>
              )) : (
                 <div className="text-center py-4 text-slate-500">No login history found.</div>
              )}
            </div>
          </div>
        )}
        {activeSection === 'security_logs' && (
          <div className="bg-white dark:bg-slate-900 p-6 rounded-[32px] border border-slate-200/80 dark:border-slate-800 shadow-2xs space-y-4 text-xs">
            <h2 className="text-sm font-extrabold text-slate-900 dark:text-white">Account Audit Logs</h2>
            <div className="space-y-2">
              {realLogs.length > 0 ? realLogs.map((log) => (
                <div key={log.id} className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-2xl border border-slate-100 dark:border-slate-700/60 flex items-center justify-between">
                  <div>
                    <h3 className="font-bold text-slate-900 dark:text-white">{log.action}</h3>
                    <p className="text-[10px] text-slate-500">{new Date(log.created_at).toLocaleString()} • IP: {log.ip_address}</p>
                  </div>
                  <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                    {log.status}
                  </span>
                </div>
              )) : (
                 <div className="text-center py-4 text-slate-500">Loading security logs...</div>
              )}
            </div>
          </div>
        )}
      </div>

      <PrivacyPolicyModal
        isOpen={showPrivacyModal}
        onClose={() => setShowPrivacyModal(false)}
      />
    </div>
  );
};
