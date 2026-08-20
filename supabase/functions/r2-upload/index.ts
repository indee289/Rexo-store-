import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.38.4';
import { S3Client, PutObjectCommand } from 'npm:@aws-sdk/client-s3@3.621.0';
import { getSignedUrl } from 'npm:@aws-sdk/s3-request-presigner@3.621.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'application/pdf',
];

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

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
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized user session' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { folder, fileName, contentType, fileSize } = await req.json();

    if (!folder || !fileName || !contentType) {
      return new Response(JSON.stringify({ error: 'folder, fileName, and contentType are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!ALLOWED_MIME_TYPES.includes(contentType)) {
      return new Response(JSON.stringify({ error: `Disallowed content-type: ${contentType}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (fileSize && fileSize > MAX_FILE_SIZE) {
      return new Response(JSON.stringify({ error: 'File exceeds maximum size of 10MB' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const r2AccountId = Deno.env.get('R2_ACCOUNT_ID');
    const r2AccessKeyId = Deno.env.get('R2_ACCESS_KEY_ID');
    const r2SecretAccessKey = Deno.env.get('R2_SECRET_ACCESS_KEY');
    const r2BucketName = Deno.env.get('R2_BUCKET_NAME');

    if (!r2AccountId || !r2AccessKeyId || !r2SecretAccessKey || !r2BucketName) {
      return new Response(
        JSON.stringify({ error: 'R2 storage environment credentials are not configured on server' }),
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

    // Generate secure unpredictable object key with random UUID
    const fileExt = fileName.includes('.') ? fileName.split('.').pop().toLowerCase() : 'bin';
    const objectUuid = crypto.randomUUID();
    const objectKey = `${folder}/${objectUuid}.${fileExt}`;

    const command = new PutObjectCommand({
      Bucket: r2BucketName,
      Key: objectKey,
      ContentType: contentType,
      Metadata: {
        uploadedBy: user.id,
        originalName: fileName.replace(/[^a-zA-Z0-9.-]/g, '_'),
      },
    });

    // Presigned upload URL valid for 15 minutes
    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 900 });

    const isPrivateFolder = folder === 'kyc-documents' || folder === 'payment-proofs' || folder === 'digital-products';
    const publicUrl = isPrivateFolder
      ? null
      : `https://${r2BucketName}.${r2AccountId}.r2.cloudflarestorage.com/${objectKey}`;

    return new Response(
      JSON.stringify({
        success: true,
        uploadUrl,
        objectKey,
        publicUrl,
        isPrivate: isPrivateFolder,
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
