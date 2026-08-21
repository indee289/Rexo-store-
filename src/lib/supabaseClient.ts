import { createClient } from '@supabase/supabase-js';

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

console.log('Supabase client initializing:', {
  url: SUPABASE_URL.substring(0, 40) + '...',
  key_length: SUPABASE_ANON_KEY.length,
});

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
    storageKey: 'rexoglobal-auth-token',
  },
});

console.log('Supabase client ready');
