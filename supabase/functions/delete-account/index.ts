// ============================================================================
// Rexo Collab — delete-account Edge Function
//
// Completes account deletion by:
//   1. Verifying the caller's JWT (identity = auth.uid(), never client input).
//   2. Running the RLS-safe RPC request_account_deletion() as the user, which
//      anonymizes profile PII and purges personal data.
//   3. Using the SERVICE ROLE to hard-delete the row in auth.users, which the
//      user JWT cannot do on its own.
//
// Deploy:
//   supabase functions deploy delete-account
// Requires (auto-injected by Supabase, do NOT hardcode):
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//
// The client invokes this with the user's access token:
//   supabase.functions.invoke('delete-account')
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return json({ error: "missing_authorization" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Client bound to the caller's JWT — used to (a) identify the user and
  // (b) run the RLS-safe RPC as that user.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) {
    return json({ error: "invalid_token" }, 401);
  }
  const userId = userData.user.id;

  // Step 1 — anonymize + purge personal data (runs as the user; RLS-safe).
  const { error: rpcErr } = await userClient.rpc("request_account_deletion", {
    p_reason: "in-app delete-account edge function",
  });
  if (rpcErr) {
    // Do not proceed to hard-delete if anonymization failed.
    return json({ error: "anonymization_failed", detail: rpcErr.message }, 500);
  }

  // Step 2 — hard-delete the auth user with the service role. This also
  // cascades to any auth-owned rows and prevents future sign-in.
  const adminClient = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { error: delErr } = await adminClient.auth.admin.deleteUser(userId);
  if (delErr) {
    // The account is already anonymized + locked (isBanned) at this point, so
    // it is unusable even if the auth-user delete needs a retry by an admin.
    return json(
      { success: false, anonymized: true, error: "auth_delete_failed", detail: delErr.message },
      207,
    );
  }

  // Mark the deletion request completed (best-effort).
  await adminClient
    .from("account_deletion_requests")
    .update({ status: "completed", completed_at: new Date().toISOString() })
    .eq("user_id", userId);

  return json({ success: true, deleted: true });
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
