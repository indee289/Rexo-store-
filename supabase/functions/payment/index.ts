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

    const { action, amount, transactionRef, paymentMethod, proofScreenshotUrl } = await req.json();

    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    if (action === 'create_deposit') {
      if (!amount || amount <= 0) {
        return new Response(JSON.stringify({ error: 'Deposit amount must be greater than 0' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const depositId = `dep_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
      const { data: deposit, error: depError } = await adminClient
        .from('deposits')
        .insert({
          id: depositId,
          user_id: user.id,
          amount: Number(amount),
          payment_method: paymentMethod || 'upi_manual',
          transaction_ref: transactionRef || `TXN${Date.now()}`,
          proof_screenshot_url: proofScreenshotUrl || '',
          status: 'pending',
          created_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (depError) {
        throw depError;
      }

      return new Response(
        JSON.stringify({
          success: true,
          deposit,
          message: 'Deposit request submitted successfully. Pending admin approval.',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (action === 'create_withdrawal') {
      if (!amount || amount <= 0) {
        return new Response(JSON.stringify({ error: 'Withdrawal amount must be greater than 0' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Check user wallet balance server-side
      const { data: wallet } = await adminClient
        .from('wallets')
        .select('id, balance')
        .eq('user_id', user.id)
        .single();

      if (!wallet || wallet.balance < amount) {
        return new Response(JSON.stringify({ error: 'Insufficient wallet balance for withdrawal' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const withdrawalId = `wth_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
      const { data: withdrawal, error: wthError } = await adminClient
        .from('withdrawals')
        .insert({
          id: withdrawalId,
          user_id: user.id,
          amount: Number(amount),
          payout_method: paymentMethod || 'upi_payout',
          account_details: transactionRef || 'Primary UPI ID',
          status: 'pending',
          created_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (wthError) {
        throw wthError;
      }

      return new Response(
        JSON.stringify({
          success: true,
          withdrawal,
          message: 'Withdrawal request created successfully.',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(JSON.stringify({ error: 'Invalid payment action specified' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Payment action failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
