import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.38.4';
import { S3Client, GetObjectCommand } from 'npm:@aws-sdk/client-s3@3.621.0';
import { getSignedUrl } from 'npm:@aws-sdk/s3-request-presigner@3.621.0';

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
    const { data: userData } = await adminClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    const isAdmin = userData?.role === 'admin';

    const { objectKey } = await req.json();
    if (!objectKey) {
      return new Response(JSON.stringify({ error: 'objectKey is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Access control check: If objectKey is in kyc-documents or payment-proofs, verify ownership or admin
    if (objectKey.startsWith('kyc-documents/') || objectKey.startsWith('payment-proofs/')) {
      if (!isAdmin) {
        // Check if user owns this document or transaction record
        const { data: kycDoc } = await adminClient
          .from('kyc_documents')
          .select('user_id')
          .eq('document_url', objectKey)
          .single();

        const { data: deposit } = await adminClient
          .from('deposits')
          .select('user_id')
          .eq('proof_screenshot_url', objectKey)
          .single();

        const isOwner = kycDoc?.user_id === user.id || deposit?.user_id === user.id;

        if (!isOwner) {
          return new Response(JSON.stringify({ error: 'Forbidden: You do not have permission to view this document' }), {
            status: 403,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }
      }
    }

    const r2AccountId = Deno.env.get('R2_ACCOUNT_ID');
    const r2AccessKeyId = Deno.env.get('R2_ACCESS_KEY_ID');
    const r2SecretAccessKey = Deno.env.get('R2_SECRET_ACCESS_KEY');
    const r2BucketName = Deno.env.get('R2_BUCKET_NAME');

    if (!r2AccountId || !r2AccessKeyId || !r2SecretAccessKey || !r2BucketName) {
      return new Response(
        JSON.stringify({ error: 'R2 storage environment credentials not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const s3Client = new S3Client({
      region: 'auto',
      endpoint: `https://${r2AccountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: r2AccessKeyId,
        secretAccessKey: r2SecretAccessKey,
      },
    });

    const command = new GetObjectCommand({
      Bucket: r2BucketName,
      Key: objectKey,
    });

    // Short lived signed URL (expires in 15 minutes = 900 seconds)
    const downloadUrl = await getSignedUrl(s3Client, command, { expiresIn: 900 });

    return new Response(
      JSON.stringify({
        success: true,
        downloadUrl,
        expiresInSeconds: 900,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
