import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabaseClient';
import { Shield, KeyRound, CheckCircle2, AlertTriangle } from 'lucide-react';
import { useStore } from '../../context/StoreContext';
import { supabaseAuthService } from '../../services/supabaseAuthService';

import { createClient } from '@supabase/supabase-js';

export const TwoFactorSetup: React.FC = () => {
  const { sessionUser, updateUserSettings } = useStore();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [factorId, setFactorId] = useState<string | null>(null);
  const [qrCode, setQrCode] = useState<string | null>(null);
  const [secret, setSecret] = useState<string | null>(null);
  const [verifyCode, setVerifyCode] = useState('');
  const [step, setStep] = useState<'idle' | 'enrolling' | 'unenrolling'>('idle');
  const [password, setPassword] = useState('');

  useEffect(() => {
    checkMfaStatus();
  }, []);

  const checkMfaStatus = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.mfa.listFactors();
      if (error) throw error;
      const totpFactor = data.totp[0];
      if (totpFactor && totpFactor.status === 'verified') {
        setFactorId(totpFactor.id);
        updateUserSettings({ twoFactorAuth: true });
      } else {
        setFactorId(null);
        updateUserSettings({ twoFactorAuth: false });
        if (totpFactor && totpFactor.status === ('unverified' as any)) {
          await supabase.auth.mfa.unenroll({ factorId: totpFactor.id });
        }
      }
    } catch (err: any) {
      console.error('Error checking MFA status', err);
    } finally {
      setLoading(false);
    }
  };

  const startEnrollment = async () => {
    setLoading(true);
    setError('');
    try {
      const { data, error } = await supabase.auth.mfa.enroll({ factorType: 'totp' });
      if (error) throw error;
      
      setFactorId(data.id);
      setQrCode(data.totp.qr_code);
      setSecret(data.totp.secret);
      setStep('enrolling');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const verifyEnrollment = async () => {
    if (!factorId || !verifyCode) return;
    setLoading(true);
    setError('');
    try {
      const challenge = await supabase.auth.mfa.challenge({ factorId });
      if (challenge.error) throw challenge.error;
      
      const verify = await supabase.auth.mfa.verify({
        factorId,
        challengeId: challenge.data.id,
        code: verifyCode
      });
      if (verify.error) throw verify.error;
      
      setStep('idle');
      updateUserSettings({ twoFactorAuth: true });
      // clear enrollment data
      setQrCode(null);
      setSecret(null);
      setVerifyCode('');
    } catch (err: any) {
      setError(err.message || 'Invalid verification code');
    } finally {
      setLoading(false);
    }
  };

  const handleDisable = async () => {
    if (!factorId || !password || !sessionUser?.email) return;
    setLoading(true);
    setError('');
    try {
      // Re-verify password without modifying main session
      const tempClient = createClient(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY, {
        auth: { persistSession: false, autoRefreshToken: false }
      });
      
      const auth = await tempClient.auth.signInWithPassword({
        email: sessionUser.email,
        password: password
      });
      
      if (auth.error) {
         throw auth.error;
      }

      const { error } = await supabase.auth.mfa.unenroll({ factorId });
      if (error) throw error;
      
      setFactorId(null);
      setStep('idle');
      setPassword('');
      updateUserSettings({ twoFactorAuth: false });
    } catch (err: any) {
      setError(err.message || 'Incorrect password or unable to disable 2FA.');
    } finally {
      setLoading(false);
    }
  };

  if (loading && step === 'idle' && !factorId) {
    return <div className="text-slate-500 py-4 text-center">Checking security settings...</div>;
  }

  return (
    <div className="space-y-4">
      {sessionUser?.role === 'admin' && !factorId && (
        <div className="bg-rose-50 border border-rose-200 rounded-2xl p-4 flex gap-3 text-rose-900">
          <AlertTriangle className="text-rose-600 shrink-0" size={20} />
          <div>
            <h4 className="font-extrabold text-sm mb-1">Admin Security Warning</h4>
            <p className="text-xs">As an administrator, you have elevated access. It is highly recommended to enable Two-Factor Authentication immediately.</p>
          </div>
        </div>
      )}

      <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800/60 rounded-2xl border border-slate-100 dark:border-slate-700/60">
        <div>
          <h3 className="font-extrabold text-slate-900 dark:text-white flex items-center gap-2">
            <Shield size={16} className={factorId ? 'text-emerald-500' : 'text-slate-400'} />
            Two-Factor Authentication
          </h3>
          <p className="text-[11px] text-slate-500 mt-0.5">Secure your account with a TOTP authenticator app</p>
        </div>
        
        {step === 'idle' && (
          <button
            onClick={() => factorId ? setStep('unenrolling') : startEnrollment()}
            disabled={loading}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              factorId 
                ? 'bg-rose-100 text-rose-700 hover:bg-rose-200'
                : 'bg-indigo-600 text-white hover:bg-indigo-700'
            }`}
          >
            {factorId ? 'Disable 2FA' : 'Enable 2FA'}
          </button>
        )}
      </div>

      {error && (
        <div className="bg-rose-50 border border-rose-200 text-rose-700 p-3 rounded-xl text-xs font-bold text-center">
          {error}
        </div>
      )}

      {step === 'enrolling' && qrCode && (
        <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl p-5 space-y-4">
          <div className="text-center">
            <h4 className="font-extrabold text-slate-900 dark:text-white mb-2">Scan QR Code</h4>
            <p className="text-xs text-slate-500 mb-4">Open Google Authenticator or Authy and scan this code:</p>
            <div className="inline-block p-2 bg-white rounded-xl border border-slate-200 mb-4">
              <img src={qrCode} alt="2FA QR Code" className="w-48 h-48" />
            </div>
            
            <div className="bg-slate-50 dark:bg-slate-900 rounded-xl p-3 border border-slate-200 dark:border-slate-700">
              <p className="text-[10px] text-slate-500 font-bold uppercase mb-1">Manual Entry Code</p>
              <code className="text-sm font-mono text-slate-900 dark:text-white font-bold tracking-wider">{secret}</code>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 dark:border-slate-700">
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-2">Enter 6-digit code</label>
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="000000"
                maxLength={6}
                value={verifyCode}
                onChange={(e) => setVerifyCode(e.target.value.replace(/\D/g, ''))}
                className="flex-1 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl p-3 text-center text-lg font-mono tracking-[0.5em] focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
              <button
                onClick={verifyEnrollment}
                disabled={loading || verifyCode.length !== 6}
                className="bg-emerald-600 hover:bg-emerald-700 text-white px-6 rounded-xl font-bold transition-all disabled:opacity-50"
              >
                Verify
              </button>
            </div>
          </div>
          
          <button 
            onClick={() => setStep('idle')} 
            className="w-full text-center text-xs font-bold text-slate-500 hover:text-slate-700 pt-2"
          >
            Cancel Setup
          </button>
        </div>
      )}

      {step === 'unenrolling' && (
        <div className="bg-rose-50 border border-rose-200 rounded-2xl p-5 space-y-4">
          <div className="flex gap-3 text-rose-900 mb-2">
            <AlertTriangle className="shrink-0" size={20} />
            <div>
              <h4 className="font-extrabold text-sm mb-1">Disable Two-Factor Authentication?</h4>
              <p className="text-xs">Your account will be less secure. Please enter your password to confirm this action.</p>
            </div>
          </div>
          
          <div className="relative">
            <KeyRound className="absolute left-3 top-3 text-rose-400" size={16} />
            <input
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-white border border-rose-200 rounded-xl py-2.5 pl-9 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-rose-500"
            />
          </div>
          
          <div className="flex gap-2">
            <button
              onClick={() => { setStep('idle'); setPassword(''); setError(''); }}
              className="flex-1 bg-white border border-slate-200 text-slate-700 py-2.5 rounded-xl font-bold text-xs"
            >
              Cancel
            </button>
            <button
              onClick={handleDisable}
              disabled={loading || !password}
              className="flex-1 bg-rose-600 hover:bg-rose-700 text-white py-2.5 rounded-xl font-bold text-xs disabled:opacity-50"
            >
              {loading ? 'Disabling...' : 'Disable 2FA'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
