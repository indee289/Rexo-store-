import { createClient } from '@supabase/supabase-js';
import { CapacitorHTTPClient } from '@supabase/supabase-js/dist/module/lib/fetch';
import { Capacitor } from '@capacitor/core';

export const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || '';
export const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

// Validate that environment variables are set (NOT empty strings)
if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    'CRITICAL: Supabase environment variables are missing or empty at build time!',
    {
      url_set: !!SUPABASE_URL,
      key_set: !!SUPABASE_ANON_KEY,
      url_length: SUPABASE_URL.length,
      key_length: SUPABASE_ANON_KEY.length,
    }
  );
}

// For native Capacitor app: use native HTTP client instead of browser fetch
// This bypasses CORS and WebView restrictions
let fetchImpl: any = fetch;
if (Capacitor.isNativePlatform()) {
  try {
    fetchImpl = CapacitorHTTPClient;
  } catch (e) {
    console.warn('CapacitorHTTPClient not available, falling back to fetch');
  }
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
    storageKey: 'rexoglobal-auth-token',
  },
  global: {
    fetch: fetchImpl,
    headers: {
      // Explicit headers to help debugging
      'X-Client-Info': `supabase-js/${typeof globalThis !== 'undefined' ? 'mobile' : 'web'}`,
    },
  },
});
