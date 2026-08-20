import React, { useState } from 'react';
import { useStore } from '../../context/StoreContext';
import {
  X,
  Shield,
  Smartphone,
  Laptop,
  Globe,
  KeyRound,
  Fingerprint,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  Lock,
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface SecuritySessionsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const SecuritySessionsModal: React.FC<SecuritySessionsModalProps> = ({
  isOpen,
  onClose,
}) => {
  const { state, userSettings, updateUserSettings, terminateSession } = useStore();
  const [activeTab, setActiveTab] = useState<'sessions' | 'security'>('sessions');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [passwordSuccess, setPasswordSuccess] = useState(false);

  if (!isOpen) return null;

  const handlePasswordChange = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPassword || newPassword.length < 6) return;
    setPasswordSuccess(true);
    setTimeout(() => {
      setPasswordSuccess(false);
      setCurrentPassword('');
      setNewPassword('');
    }, 2000);
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
                <Shield size={22} className="stroke-[2.2px]" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900">Security & Login Sessions</h3>
                <p className="text-xs text-slate-500 font-medium">Device Access & Two-Factor Controls</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-slate-200 transition-colors"
            >
              <X size={16} />
            </button>
          </div>

          {/* Nav Tabs */}
          <div className="flex border-b border-slate-100 mt-2">
            <button
              onClick={() => setActiveTab('sessions')}
              className={`flex-1 py-2.5 text-xs font-bold transition-all border-b-2 ${
                activeTab === 'sessions'
                  ? 'border-indigo-600 text-indigo-600'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              Active Devices ({state.userSessions.length})
            </button>
            <button
              onClick={() => setActiveTab('security')}
              className={`flex-1 py-2.5 text-xs font-bold transition-all border-b-2 ${
                activeTab === 'security'
                  ? 'border-indigo-600 text-indigo-600'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              Password & 2FA
            </button>
          </div>

          {/* Content */}
          <div className="overflow-y-auto py-4 space-y-4 pr-1">
            {activeTab === 'sessions' ? (
              <div className="space-y-3">
                <p className="text-xs text-slate-500 font-medium">
                  Logged in devices associated with your Rexo unified ID. You can remotely terminate suspicious sessions.
                </p>

                {state.userSessions.map((sess) => (
                  <div
                    key={sess.id}
                    className={`p-4 rounded-2xl border transition-all ${
                      sess.isCurrent
                        ? 'border-indigo-600 bg-indigo-50/20'
                        : 'border-slate-200 bg-white hover:border-slate-300'
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-start gap-3">
                        <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-700 shrink-0">
                          {sess.deviceName.toLowerCase().includes('mac') || sess.deviceName.toLowerCase().includes('laptop') ? (
                            <Laptop size={20} />
                          ) : (
                            <Smartphone size={20} />
                          )}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h5 className="text-xs font-bold text-slate-900">{sess.deviceName}</h5>
                            {sess.isCurrent && (
                              <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-md">
                                This Device
                              </span>
                            )}
                          </div>
                          <p className="text-xs text-slate-500 font-medium mt-0.5">
                            {sess.browser} • {sess.os}
                          </p>
                          <p className="text-[11px] text-slate-400 font-mono mt-1">
                            IP: {sess.ipAddress} • {sess.location}
                          </p>
                        </div>
                      </div>

                      {!sess.isCurrent && (
                        <button
                          onClick={() => terminateSession(sess.id)}
                          className="p-2 rounded-xl bg-slate-100 hover:bg-rose-50 text-slate-400 hover:text-rose-600 transition-colors"
                          title="Terminate Session"
                        >
                          <Trash2 size={15} />
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="space-y-5">
                {/* 2FA & Biometric toggles */}
                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <KeyRound size={18} className="text-indigo-600" />
                      <div>
                        <h5 className="text-xs font-bold text-slate-900">Two-Factor Authentication (2FA)</h5>
                        <p className="text-[11px] text-slate-500 font-medium">Require SMS / Authenticator OTP for logins</p>
                      </div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={userSettings.twoFactorAuth}
                        onChange={(e) => updateUserSettings({ twoFactorAuth: e.target.checked })}
                        className="sr-only peer"
                      />
                      <div className="w-9 h-5 bg-slate-200 peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-indigo-600"></div>
                    </label>
                  </div>

                  <div className="flex items-center justify-between pt-2 border-t border-slate-200">
                    <div className="flex items-center gap-2.5">
                      <Fingerprint size={18} className="text-indigo-600" />
                      <div>
                        <h5 className="text-xs font-bold text-slate-900">Biometric / Passkey Login</h5>
                        <p className="text-[11px] text-slate-500 font-medium">Use TouchID, FaceID or Windows Hello</p>
                      </div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={userSettings.biometricAuth}
                        onChange={(e) => updateUserSettings({ biometricAuth: e.target.checked })}
                        className="sr-only peer"
                      />
                      <div className="w-9 h-5 bg-slate-200 peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-indigo-600"></div>
                    </label>
                  </div>
                </div>

                {/* Change Password Form */}
                <form onSubmit={handlePasswordChange} className="space-y-3">
                  <h5 className="text-xs font-bold text-slate-900 uppercase tracking-wider">Change Account Password</h5>

                  {passwordSuccess && (
                    <div className="p-3 rounded-xl bg-emerald-50 text-emerald-800 text-xs font-bold flex items-center gap-2">
                      <CheckCircle2 size={16} />
                      <span>Account password updated securely!</span>
                    </div>
                  )}

                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">Current Password</label>
                    <input
                      type="password"
                      required
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                    />
                  </div>

                  <div>
                    <label className="text-xs font-bold text-slate-700 block mb-1">New Strong Password</label>
                    <input
                      type="password"
                      required
                      minLength={6}
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="At least 6 characters"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-medium text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:bg-white"
                    />
                  </div>

                  <button
                    type="submit"
                    className="w-full py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs shadow-xs transition-colors"
                  >
                    Update Password
                  </button>
                </form>
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
