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

    // Verify system admin role from server-side database
    const { data: requesterData, error: reqErr } = await adminClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (reqErr || requesterData?.role !== 'admin') {
      return new Response(
        JSON.stringify({ error: 'Forbidden: Requester does not possess administrator credentials' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { action, targetUserId, depositId, withdrawalId, kycDocId, status, rejectionReason } = await req.json();

    if (action === 'update_user_status') {
      const { data: updatedUser, error: updateErr } = await adminClient
        .from('users')
        .update({ account_status: status })
        .eq('id', targetUserId)
        .select()
        .single();

      if (updateErr) throw updateErr;

      return new Response(JSON.stringify({ success: true, user: updatedUser }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'process_deposit') {
      // Approve/Reject deposit and credit wallet safely
      const { data: deposit, error: depErr } = await adminClient
        .from('deposits')
        .select('*')
        .eq('id', depositId)
        .single();

      if (depErr || !deposit) throw new Error('Deposit request not found');

      const newStatus = status === 'approved' ? 'approved' : 'rejected';
      await adminClient.from('deposits').update({ status: newStatus }).eq('id', depositId);

      if (newStatus === 'approved') {
        // Find or create wallet for target user
        let { data: wallet } = await adminClient
          .from('wallets')
          .select('id, balance')
          .eq('user_id', deposit.user_id)
          .single();

        if (!wallet) {
          const { data: newWallet } = await adminClient
            .from('wallets')
            .insert({ user_id: deposit.user_id, balance: deposit.amount })
            .select()
            .single();
          wallet = newWallet;
        } else {
          await adminClient
            .from('wallets')
            .update({ balance: wallet.balance + deposit.amount })
            .eq('id', wallet.id);
        }

        // Insert completed transaction log
        await adminClient.from('transactions').insert({
          id: `txn_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
          wallet_id: wallet?.id,
          user_id: deposit.user_id,
          title: 'Deposit Approved',
          amount: deposit.amount,
          type: 'deposit',
          status: 'completed',
          created_at: new Date().toISOString(),
        });
      }

      return new Response(JSON.stringify({ success: true, depositId, status: newStatus }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'process_kyc') {
      const { data: kycDoc, error: kycErr } = await adminClient
        .from('kyc_documents')
        .update({
          status: status === 'verified' ? 'verified' : 'rejected',
          rejection_reason: rejectionReason || null,
        })
        .eq('id', kycDocId)
        .select()
        .single();

      if (kycErr) throw kycErr;

      if (status === 'verified') {
        await adminClient
          .from('users')
          .update({ kyc_status: 'verified' })
          .eq('id', kycDoc.user_id);
      }

      return new Response(JSON.stringify({ success: true, kycDoc }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'Unknown admin action' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Admin action failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
