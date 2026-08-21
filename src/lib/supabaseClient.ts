import { createClient } from '@supabase/supabase-js';
import { Capacitor } from '@capacitor/core';
import { CapacitorHttp } from '@capacitor/core';

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

// Create custom fetch for Capacitor native platform to bypass CORS/WebView restrictions
const createCapacitorFetch = () => {
  return async (url: string, options?: RequestInit) => {
    if (!Capacitor.isNativePlatform()) {
      // Fall back to regular fetch on web
      return fetch(url, options);
    }

    try {
      const method = options?.method || 'GET';
      const headers: Record<string, string> = {};
      
      if (options?.headers) {
        const headerObj = options.headers as Record<string, string> | Headers;
        if (headerObj instanceof Headers) {
          headerObj.forEach((value, key) => {
            headers[key] = value;
          });
        } else {
          Object.assign(headers, headerObj);
        }
      }

      const response = await CapacitorHttp.request({
        url: url as string,
        method: method as any,
        headers,
        data: options?.body ? JSON.parse(options.body as string) : undefined,
      });

      return new Response(JSON.stringify(response.data), {
        status: response.status,
        statusText: response.statusText,
        headers: new Headers(response.headers),
      });
    } catch (error) {
      console.error('Capacitor HTTP request failed:', error);
      // Fall back to regular fetch on error
      return fetch(url, options);
    }
  };
};

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
    storageKey: 'rexoglobal-auth-token',
  },
  global: {
    fetch: Capacitor.isNativePlatform() ? createCapacitorFetch() : undefined,
  },
});
