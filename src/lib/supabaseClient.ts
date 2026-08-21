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

// Custom fetch implementation for Capacitor native to bypass CORS/WebView restrictions
async function capacitorFetch(url: string, options?: RequestInit): Promise<Response> {
  console.log('capacitorFetch called for:', url);
  
  // Only use Capacitor HTTP on native platform
  if (!Capacitor.isNativePlatform()) {
    console.log('Web platform detected, using browser fetch');
    return fetch(url, options);
  }

  try {
    console.log('Native platform detected, using CapacitorHttp');
    
    const method = (options?.method || 'GET').toUpperCase();
    const headers: Record<string, string> = {};
    
    // Convert headers to plain object
    if (options?.headers) {
      if (options.headers instanceof Headers) {
        options.headers.forEach((value, key) => {
          headers[key] = value;
        });
      } else if (typeof options.headers === 'object') {
        Object.assign(headers, options.headers);
      }
    }

    console.log('CapacitorHttp request:', { url, method, headers: Object.keys(headers) });

    let body: any = undefined;
    if (options?.body) {
      try {
        body = typeof options.body === 'string' ? JSON.parse(options.body) : options.body;
      } catch (e) {
        body = options.body;
      }
    }

    const response = await CapacitorHttp.request({
      url,
      method: method as any,
      headers,
      data: body,
    });

    console.log('CapacitorHttp response:', { status: response.status, statusText: response.statusText });

    // Return Response object compatible with Fetch API
    return new Response(JSON.stringify(response.data), {
      status: response.status,
      statusText: response.statusText || 'OK',
      headers: new Headers(response.headers || {}),
    });
  } catch (error: any) {
    console.error('Capacitor HTTP request failed, falling back to fetch:', error);
    console.error('Error details:', {
      message: error?.message,
      code: error?.code,
      error_description: error?.error_description,
    });
    
    // Fall back to regular fetch
    try {
      return fetch(url, options);
    } catch (fallbackError) {
      console.error('Fallback fetch also failed:', fallbackError);
      throw fallbackError;
    }
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
    // Provide custom fetch for Capacitor native platform
    fetch: Capacitor.isNativePlatform() ? capacitorFetch : fetch,
  },
});

// Log initialization
console.log('Supabase client initialized:', {
  platform: Capacitor.isNativePlatform() ? 'native' : 'web',
  url: SUPABASE_URL.substring(0, 30) + '...',
  key_length: SUPABASE_ANON_KEY.length,
  fetch_impl: Capacitor.isNativePlatform() ? 'capacitorFetch' : 'browser fetch',
});
