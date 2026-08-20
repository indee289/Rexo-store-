import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.38.4';
import { GoogleGenAI } from 'npm:@google/genai@0.1.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const FAST_SPAM_WORDS = ['buy followers', 'ponzi', 'free money', 'whatsapp me', 'telegram me', 'crypto scam', 'cash app'];

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
      return new Response(JSON.stringify({ error: 'Unauthorized session' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { text, type } = await req.json();

    if (!text) {
      return new Response(JSON.stringify({ error: 'Text content is required for moderation' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 1. Fast Rule Check
    const lowerText = text.toLowerCase();
    for (const phrase of FAST_SPAM_WORDS) {
      if (lowerText.includes(phrase)) {
        return new Response(
          JSON.stringify({
            risk_score: 95,
            confidence_score: 100,
            category: 'spam_scam',
            reason: `Contains prohibited phrase: ${phrase}`,
            recommended_action: 'shadow_ban',
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // 2. Gemini AI Check via Server-Side Key
    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) {
      return new Response(
        JSON.stringify({
          risk_score: 0,
          confidence_score: 0,
          category: 'safe',
          reason: 'AI key not configured on server. Passed.',
          recommended_action: 'none',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const ai = new GoogleGenAI({ apiKey: geminiKey });
    const prompt = `You are an enterprise-grade Trust & Safety AI moderator.
Analyze this submitted ${type || 'text'} on a creator/brand marketplace:
"${text}"

Detect: harassment, hate speech, spam, scam, fake engagement requests, adult content, or policy violations.
Return strictly valid JSON:
{
  "risk_score": <number 0-100>,
  "confidence_score": <number 0-100>,
  "category": <"safe" | "abusive" | "spam" | "scam" | "adult" | "harassment" | "policy_violation">,
  "reason": <short string>,
  "recommended_action": <"none" | "warn" | "suspend" | "shadow_ban" | "manual_review">
}`;

    const aiResponse = await ai.models.generateContent({
      model: 'gemini-1.5-flash',
      contents: prompt,
      config: { responseMimeType: 'application/json' },
    });

    const result = JSON.parse(aiResponse.text || '{}');

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || 'Moderation processing failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
