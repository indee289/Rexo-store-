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

  // Service-role client for storage cleanup + auth-user deletion.
  const adminClient = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Step 1b — delete ONLY the caller's own Storage objects (scoped to the
  // `<userId>/…` folder in each bucket; never an arbitrary path). Best-effort:
  // the DB data is already anonymized, so a storage hiccup must not block the
  // account deletion.
  await purgeUserStorage(adminClient, userId);

  // Step 2 — hard-delete the auth user with the service role. This also
  // cascades to any auth-owned rows and prevents future sign-in.
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

// Buckets that may hold user-owned objects under a `<userId>/…` prefix.
const USER_BUCKETS = [
  "avatars",
  "kyc-documents",
  "deposit-proofs",
  "campaign-assets",
  "product-images",
];

// deno-lint-ignore no-explicit-any
async function purgeUserStorage(admin: any, userId: string): Promise<void> {
  for (const bucket of USER_BUCKETS) {
    try {
      await walkAndRemove(admin, bucket, userId);
    } catch (_) {
      // Ignore per-bucket errors — deletion of DB data already succeeded.
    }
  }
}

// deno-lint-ignore no-explicit-any
async function walkAndRemove(admin: any, bucket: string, prefix: string): Promise<void> {
  const { data, error } = await admin.storage.from(bucket).list(prefix, {
    limit: 1000,
  });
  if (error || !data) return;

  const files: string[] = [];
  for (const entry of data) {
    const full = `${prefix}/${entry.name}`;
    // Directory entries have null id/metadata → recurse; files are removed.
    if (entry.id == null && entry.metadata == null) {
      await walkAndRemove(admin, bucket, full);
    } else {
      files.push(full);
    }
  }
  if (files.length > 0) {
    await admin.storage.from(bucket).remove(files);
  }
}
