import { createClient } from '@supabase/supabase-js';

const DEFAULT_SUPABASE_URL = 'https://npzomevhjdxbgbuojwoo.supabase.co';
const DEFAULT_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wem9tZXZoamR4YmdidW9qd29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNzM0NDMsImV4cCI6MjEwMjY0OTQ0M30.pDVcqRty6QBtAECvZgNcgsK_eLQZDvwHOuHzLw4VrjI';

const rawUrl = import.meta.env.VITE_SUPABASE_URL;
const rawKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const SUPABASE_URL = (rawUrl && rawUrl !== 'https://your-supabase-project.supabase.co' && rawUrl.startsWith('http'))
  ? rawUrl
  : DEFAULT_SUPABASE_URL;

export const SUPABASE_ANON_KEY = (rawKey && rawKey !== 'your_supabase_anon_public_key' && rawKey.length > 20)
  ? rawKey
  : DEFAULT_SUPABASE_ANON_KEY;

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
    storageKey: 'rexoglobal-auth-token',
  },
});
