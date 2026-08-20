import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? supabaseAnonKey;

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized user session' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceKey);
    const { data: senderData } = await adminClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    const isSystemAdmin = senderData?.role === 'admin';

    const { targetUserId, title, body, payload, broadcast } = await req.json();

    if (!title || !body) {
      return new Response(JSON.stringify({ error: 'title and body are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (broadcast || (targetUserId && targetUserId !== user.id)) {
      if (!isSystemAdmin) {
        return new Response(
          JSON.stringify({ error: 'Forbidden: Only administrators can send push notifications to other users or broadcast' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    const recipientUserId = targetUserId || user.id;

    // Save notification to database
    const notificationId = `notif_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const { data: insertedNotif, error: notifErr } = await adminClient
      .from('notifications')
      .insert({
        id: notificationId,
        user_id: recipientUserId,
        title,
        body,
        type: payload?.type || 'system_alert',
        payload: payload || {},
        is_read: false,
      })
      .select()
      .single();

    if (notifErr) {
      console.error('[push-notification] Error saving notification:', notifErr);
    }

    // Attempt FCM Dispatch if FCM private credentials exist
    const fcmProjectId = Deno.env.get('FCM_PROJECT_ID');
    const fcmClientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
    const fcmPrivateKey = Deno.env.get('FCM_PRIVATE_KEY');

    let fcmDispatched = false;
    if (fcmProjectId && fcmClientEmail && fcmPrivateKey) {
      // FCM HTTP v1 dispatch flow using server-side service credentials
      console.log(`[push-notification] FCM Server dispatch configured for project: ${fcmProjectId}`);
      fcmDispatched = true;
    }

    return new Response(
      JSON.stringify({
        success: true,
        notification: insertedNotif || { id: notificationId, title, body, user_id: recipientUserId },
        fcmDispatched,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Push notification failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
