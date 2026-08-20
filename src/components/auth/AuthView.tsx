import React, { useState } from 'react';
import { Sparkles, Mail, Lock, User, LogIn, UserPlus, Shield } from 'lucide-react';
import { supabaseAuthService } from '../../services/supabaseAuthService';
import { useStore } from '../../context/StoreContext';
import { supabase } from '../../lib/supabaseClient';

interface AuthViewProps {
  onSuccess: () => void;
}

export const AuthView: React.FC<AuthViewProps> = ({ onSuccess }) => {
  const { setRealSessionUser } = useStore();
  const [mode, setMode] = useState<'login' | 'signup' | 'mfa'>('login');
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState<'creator' | 'brand'>('creator');
  const [mfaCode, setMfaCode] = useState('');
  const [mfaFactorId, setMfaFactorId] = useState<string | null>(null);
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const loadProfileAndFinish = async (userId: string) => {
    const profile = await supabaseAuthService.getUserProfile(userId);
    if (profile) {
      setRealSessionUser(profile);
      onSuccess();
    } else {
      throw new Error('User profile not found in database.');
    }
  };

  const handleMfaSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!mfaFactorId) return;
    setLoading(true);
    setError('');
    
    try {
      const challenge = await supabase.auth.mfa.challenge({ factorId: mfaFactorId });
      if (challenge.error) throw challenge.error;
      
      const verify = await supabase.auth.mfa.verify({
        factorId: mfaFactorId,
        challengeId: challenge.data.id,
        code: mfaCode
      });
      if (verify.error) throw verify.error;
      
      // Verification succeeded, user is fully signed in
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await loadProfileAndFinish(user.id);
      }
    } catch (err: any) {
      setError(err.message || 'Invalid authenticator code');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      if (mode === 'signup') {
        const { user, profile, error: signUpErr } = await supabaseAuthService.signUp(email, password, name, role);
        if (signUpErr) throw signUpErr;
        
        if (user && profile) {
          setRealSessionUser(profile);
          onSuccess();
        }
      } else if (mode === 'login') {
        const { user, error: signInErr } = await supabaseAuthService.signIn(email, password);
        if (signInErr) {
          throw signInErr;
        }
        
        if (user) {
          // Check for MFA
          const { data: mfaData, error: mfaError } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
          if (mfaError) throw mfaError;
          
          if (mfaData.nextLevel === 'aal2' && mfaData.nextLevel !== mfaData.currentLevel) {
            // Need MFA
            const factors = await supabase.auth.mfa.listFactors();
            const totpFactor = factors.data?.totp?.[0];
            
            if (totpFactor) {
              setMfaFactorId(totpFactor.id);
              setMode('mfa');
              setLoading(false);
              return; // Stop here, wait for MFA code
            }
          }
          
          // No MFA required
          await loadProfileAndFinish(user.id);
        }
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred during authentication.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col justify-center items-center p-6">
      <div className="w-full max-w-sm bg-white rounded-3xl p-8 shadow-xl border border-slate-100">
        
        <div className="flex flex-col items-center mb-8">
          <div className="w-14 h-14 bg-slate-900 rounded-2xl flex items-center justify-center shadow-lg shadow-slate-900/20 mb-4">
            {mode === 'mfa' ? <Shield className="text-emerald-400" size={28} /> : <Sparkles className="text-white" size={28} />}
          </div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">
            {mode === 'mfa' ? 'Two-Factor Auth' : 'Rexo Global'}
          </h1>
          <p className="text-slate-500 text-sm font-medium mt-1">
            {mode === 'mfa' ? 'Enter code from your authenticator app.' : mode === 'login' ? 'Welcome back.' : 'Create your account.'}
          </p>
        </div>

        {error && (
          <div className="mb-6 p-3 bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold rounded-xl text-center">
            {error}
          </div>
        )}

        {mode === 'mfa' ? (
          <form onSubmit={handleMfaSubmit} className="space-y-4">
            <div>
              <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-1.5 text-center">6-Digit Code</label>
              <input
                type="text"
                required
                maxLength={6}
                value={mfaCode}
                onChange={(e) => setMfaCode(e.target.value.replace(/\D/g, ''))}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-4 text-center text-xl tracking-[0.5em] font-mono font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
                placeholder="000000"
              />
            </div>
            <button
              type="submit"
              disabled={loading || mfaCode.length !== 6}
              className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-black py-3 rounded-xl shadow-lg shadow-emerald-600/20 transition-all active:scale-95 flex items-center justify-center gap-2 mt-6 disabled:opacity-70 disabled:active:scale-100"
            >
              {loading ? (
                <span className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                'Verify & Sign In'
              )}
            </button>
            <button 
              type="button"
              onClick={() => { setMode('login'); supabase.auth.signOut(); }}
              className="w-full mt-4 text-xs font-bold text-slate-500 hover:text-slate-800"
            >
              Cancel Login
            </button>
          </form>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {mode === 'signup' && (
              <>
                <div>
                  <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-1.5">Full Name</label>
                  <div className="relative">
                    <User className="absolute left-3.5 top-3 text-slate-400" size={18} />
                    <input
                      type="text"
                      required
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 pl-10 pr-4 text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition-all"
                      placeholder="John Doe"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-1.5">I am a</label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setRole('creator')}
                      className={`py-2 rounded-xl text-xs font-bold transition-all ${
                        role === 'creator'
                          ? 'bg-slate-900 text-white shadow-md'
                          : 'bg-slate-50 text-slate-500 border border-slate-200 hover:bg-slate-100'
                      }`}
                    >
                      Creator
                    </button>
                    <button
                      type="button"
                      onClick={() => setRole('brand')}
                      className={`py-2 rounded-xl text-xs font-bold transition-all ${
                        role === 'brand'
                          ? 'bg-slate-900 text-white shadow-md'
                          : 'bg-slate-50 text-slate-500 border border-slate-200 hover:bg-slate-100'
                      }`}
                    >
                      Brand
                    </button>
                  </div>
                </div>
              </>
            )}

            <div>
              <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-1.5">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-3 text-slate-400" size={18} />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 pl-10 pr-4 text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition-all"
                  placeholder="hello@example.com"
                />
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-1.5">Password</label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-3 text-slate-400" size={18} />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 pl-10 pr-4 text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition-all"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-slate-900 hover:bg-slate-800 text-white font-black py-3 rounded-xl shadow-lg shadow-slate-900/20 transition-all active:scale-95 flex items-center justify-center gap-2 mt-6 disabled:opacity-70 disabled:active:scale-100"
            >
              {loading ? (
                <span className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : mode === 'login' ? (
                <>
                  <LogIn size={18} />
                  Sign In securely
                </>
              ) : (
                <>
                  <UserPlus size={18} />
                  Create Account
                </>
              )}
            </button>
          </form>
        )}

        {mode !== 'mfa' && (
          <div className="mt-6 text-center">
            <button
              onClick={() => {
                setMode(mode === 'login' ? 'signup' : 'login');
                setError('');
              }}
              className="text-[13px] font-bold text-slate-500 hover:text-slate-900 transition-colors"
            >
              {mode === 'login'
                ? "Don't have an account? Sign up"
                : 'Already have an account? Sign in'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
