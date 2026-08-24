// ============================================================================
// Supabase Edge Function: send-broadcast
//
// Sends an admin broadcast: inserts one in-app notification row per target user
// AND delivers a real FCM push (HTTP v1) to each of their registered devices.
//
// This function is the AUTHORITATIVE path for broadcasts. The Flutter client
// only calls this function (functions.invoke('send-broadcast', ...)) — it does
// NOT insert notification rows itself, so there are no duplicates.
//
// WHY an Edge Function (and not the app):
//   Minting a Google OAuth2 access token for FCM HTTP v1 requires RS256-signing
//   a JWT with the service-account PRIVATE KEY. Embedding that key in the APK is
//   insecure, and the old client code produced an UNSIGNED assertion that Google
//   always rejected. Signing happens here, server-side, with Web Crypto.
//
// ---------------------------------------------------------------------------
// DEPLOY (NEEDS-USER-ACTION) — run from the repo root with the Supabase CLI.
//
// The values come from the Firebase service-account JSON (Project Settings ->
// Service accounts -> Generate new private key): project_id, client_email,
// private_key. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected
// automatically by the platform; you never set them manually.
//
//   1) STRONGLY RECOMMENDED — set the private key as single-line base64.
//      A multi-line PEM passed through the shell/CLI is routinely mangled
//      (literal "\n" not converted, double-escaping, or truncation), which
//      corrupts the PKCS8 DER and makes FCM push fail with
//      "incorrect length for APPLICATION [15] (constructed)". Base64-encoding
//      the whole PEM into ONE line sidesteps all of that.
//
//      First extract the private_key from the service-account JSON into a .pem
//      file (must start with "-----BEGIN PRIVATE KEY-----" — PKCS8, NOT
//      "-----BEGIN RSA PRIVATE KEY-----" which is PKCS1 and unsupported by
//      Web Crypto; convert PKCS1 -> PKCS8 with:
//        openssl pkcs8 -topk8 -nocrypt -in pkcs1.pem -out service-account-private-key.pem
//      ), then:
//
//        B64=$(base64 -w0 < service-account-private-key.pem)   # Linux
//        # macOS: B64=$(base64 < service-account-private-key.pem | tr -d '\n')
//        supabase secrets set \
//          FCM_PROJECT_ID="your-firebase-project-id" \
//          FCM_CLIENT_EMAIL="firebase-adminsdk-xxxx@your-project.iam.gserviceaccount.com" \
//          FCM_PRIVATE_KEY_B64="$B64"
//
//   1-alt) FALLBACK — raw PEM secret (only if you cannot use base64). It must
//      be a PKCS8 key and contain literal "\n" escapes; this function converts
//      "\n" back to real newlines:
//        supabase secrets set \
//          FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
//
//   2) Deploy:
//        supabase functions deploy send-broadcast
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface BroadcastBody {
  title?: string;
  message?: string;
  // Optional target filter. Defaults to all users when omitted.
  userIds?: string[];
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// --- base64url helpers -------------------------------------------------------
function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function strToBase64Url(str: string): string {
  return base64UrlEncode(new TextEncoder().encode(str));
}

// Distinguishes the private-key failure modes so the caller can surface a
// concise, actionable (and sanitized) diagnostic without leaking key material.
class PrivateKeyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PrivateKeyError";
  }
}

// Convert a PEM PKCS8 private key into an ArrayBuffer of DER bytes.
//
// ROBUST: after removing the BEGIN/END markers we strip EVERY character that is
// not valid base64 (A-Z a-z 0-9 + / =). This removes real newlines, spaces AND
// any stray literal "\n" / backslashes that survive secret-escaping — those
// stray chars were corrupting the DER and caused the FCM push to fail with
// "incorrect length for APPLICATION [15]" when importing the key.
//
// It also fails FAST with a clear message for the two other common causes of
// that DER error: a PKCS1 key (Web Crypto's importKey('pkcs8', ...) only
// accepts PKCS8) and an empty/undecodable base64 body.
function pemToArrayBuffer(pem: string): ArrayBuffer {
  // PKCS1 keys ("BEGIN RSA PRIVATE KEY") are DER-incompatible with the pkcs8
  // importer and are a frequent cause of the "incorrect length" DER error.
  if (/-----BEGIN RSA PRIVATE KEY-----/.test(pem)) {
    throw new PrivateKeyError(
      "invalid private key format (expected PKCS8): got a PKCS1 " +
        '"BEGIN RSA PRIVATE KEY" key. Convert it with: ' +
        "openssl pkcs8 -topk8 -nocrypt -in pkcs1.pem -out pkcs8.pem",
    );
  }
  if (!/-----BEGIN PRIVATE KEY-----/.test(pem)) {
    throw new PrivateKeyError(
      "invalid private key format (expected PKCS8): missing " +
        '"BEGIN PRIVATE KEY" PEM header',
    );
  }

  const cleaned = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/[^A-Za-z0-9+/=]/g, "");
  if (cleaned.length === 0) {
    throw new PrivateKeyError(
      "invalid private key format (expected PKCS8): empty key body after " +
        "decoding — check the secret is not truncated",
    );
  }

  let binary: string;
  try {
    binary = atob(cleaned);
  } catch (_) {
    throw new PrivateKeyError(
      "invalid private key format (expected PKCS8): base64 body could not " +
        "be decoded — the secret is likely corrupted or truncated",
    );
  }
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

// Mint a Google OAuth2 access token for the firebase.messaging scope by
// RS256-signing a JWT with the service-account private key.
async function getAccessToken(
  clientEmail: string,
  privateKeyPem: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const unsigned = `${strToBase64Url(JSON.stringify(header))}.${
    strToBase64Url(JSON.stringify(claims))
  }`;

  // pemToArrayBuffer throws PrivateKeyError (clear format diagnostics) which we
  // let propagate. importKey itself throws a low-level DOMException on a
  // malformed/corrupt PKCS8 DER (e.g. "incorrect length for APPLICATION [15]");
  // translate that into an actionable PrivateKeyError too.
  let key: CryptoKey;
  try {
    key = await crypto.subtle.importKey(
      "pkcs8",
      pemToArrayBuffer(privateKeyPem),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
  } catch (e) {
    if (e instanceof PrivateKeyError) throw e;
    throw new PrivateKeyError(
      "invalid private key format (expected PKCS8): the key bytes could not " +
        "be parsed as PKCS8 DER — recommend setting FCM_PRIVATE_KEY_B64 " +
        "(single-line base64 of the PEM) to avoid newline/escaping corruption",
    );
  }

  const signatureBuf = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );

  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signatureBuf))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    // Surface the provider's short error code (e.g. "invalid_grant") but not
    // the full body, which can be verbose. Never includes key material.
    let code = "";
    try {
      const errJson = await res.json();
      code = errJson?.error ?? "";
    } catch (_) {
      // ignore non-JSON bodies
    }
    throw new Error(
      `OAuth token exchange failed (${res.status}${code ? `: ${code}` : ""})`,
    );
  }
  const data = await res.json();
  return data.access_token as string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const fcmProjectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
  const fcmClientEmail = Deno.env.get("FCM_CLIENT_EMAIL") ?? "";
  // Prefer FCM_PRIVATE_KEY_B64: a single-line base64 of the raw PEM set by the
  // deploy workflow. This is immune to the newline/escaping/truncation issues
  // that corrupt a multi-line PEM secret passed through the CLI (which caused
  // the "incorrect length for APPLICATION [15]" DER error). Fall back to the
  // raw FCM_PRIVATE_KEY secret (with literal "\n" restored) if B64 is absent.
  const fcmPrivateKey = (() => {
    const b64 = (Deno.env.get("FCM_PRIVATE_KEY_B64") ?? "").replace(
      /[^A-Za-z0-9+/=]/g,
      "",
    );
    if (b64) {
      try {
        return atob(b64);
      } catch (_) {
        // fall through to the raw secret
      }
    }
    return (Deno.env.get("FCM_PRIVATE_KEY") ?? "").replace(/\\n/g, "\n");
  })();

  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "Server misconfigured" }, 500);
  }

  // --- AuthN/AuthZ: require a valid caller JWT that belongs to an admin ------
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  // Service-role client — bypasses RLS for inserts/reads below.
  const admin = createClient(supabaseUrl, serviceRoleKey);

  // Resolve the caller from their JWT, then confirm role='admin'.
  const { data: userData, error: userErr } = await admin.auth.getUser(token);
  if (userErr || !userData?.user) {
    return json({ error: "Invalid or expired session" }, 401);
  }
  const callerId = userData.user.id;

  const { data: callerRow, error: roleErr } = await admin
    .from("users")
    .select("role")
    .eq("id", callerId)
    .single();

  if (roleErr || !callerRow || callerRow.role !== "admin") {
    return json({ error: "Forbidden: admin only" }, 403);
  }

  // --- Parse input -----------------------------------------------------------
  let body: BroadcastBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const title = (body.title ?? "").trim();
  const message = (body.message ?? "").trim();
  if (!title || !message) {
    return json({ error: "title and message are required" }, 400);
  }

  // --- Resolve target users --------------------------------------------------
  let targetUserIds: string[];
  if (Array.isArray(body.userIds) && body.userIds.length > 0) {
    targetUserIds = body.userIds;
  } else {
    const { data: users, error: usersErr } = await admin
      .from("users")
      .select("id");
    if (usersErr) {
      return json({ error: "Failed to load users" }, 500);
    }
    targetUserIds = (users ?? []).map((u: { id: string }) => u.id);
  }

  if (targetUserIds.length === 0) {
    return json({ inserted: 0, pushed: 0, failed: 0, message: "No targets" });
  }

  // --- 1) Insert one in-app notification row per user (service role) ---------
  const nowIso = new Date().toISOString();
  const rows = targetUserIds.map((uid) => ({
    user_id: uid,
    title,
    body: message,
    type: "broadcast",
    is_read: false,
    created_at: nowIso,
  }));

  const { error: insertErr } = await admin.from("notifications").insert(rows);
  if (insertErr) {
    return json({ error: "Failed to insert notifications" }, 500);
  }
  const inserted = rows.length;

  // --- 2) Best-effort FCM push -----------------------------------------------
  let pushed = 0;
  let failed = 0;
  let pushError: string | null = null;

  if (fcmProjectId && fcmClientEmail && fcmPrivateKey) {
    // Fetch FCM tokens for the target users.
    const { data: devices } = await admin
      .from("user_devices")
      .select("fcm_token")
      .in("user_id", targetUserIds);

    const tokens = (devices ?? [])
      .map((d: { fcm_token: string | null }) => d.fcm_token)
      .filter((t): t is string => !!t && t.length > 0);

    if (tokens.length > 0) {
      try {
        const accessToken = await getAccessToken(fcmClientEmail, fcmPrivateKey);
        const fcmUrl =
          `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`;

        // Send sequentially in small chunks to stay within limits.
        for (const token of tokens) {
          try {
            const resp = await fetch(fcmUrl, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify({
                message: {
                  token,
                  notification: { title, body: message },
                  // Android: deliver as a high-priority heads-up notification
                  // with sound, on the app's high-importance channel, so it
                  // shows in the status bar / lock screen (not just in-app).
                  android: {
                    priority: "high",
                    notification: {
                      channel_id: "rexo_high_importance",
                      sound: "default",
                      default_sound: true,
                      notification_priority: "PRIORITY_HIGH",
                    },
                  },
                  // iOS: play the default sound.
                  apns: {
                    payload: { aps: { sound: "default" } },
                  },
                },
              }),
            });
            if (resp.ok) {
              pushed++;
            } else {
              failed++;
            }
          } catch {
            failed++;
          }
        }
      } catch (e) {
        // Never crash: in-app rows are already inserted. Record a sanitized,
        // concise diagnostic that distinguishes the failure mode.
        if (e instanceof PrivateKeyError) {
          pushError = e.message;
        } else if (e instanceof Error && e.message.startsWith("OAuth token")) {
          pushError = e.message;
        } else {
          pushError = "FCM push failed (token/dispatch error)";
        }
        // The token exchange/key step failed before any per-device send, so no
        // device received the push — record every target device as failed.
        if (pushed === 0 && failed === 0) failed = tokens.length;
        console.error("send-broadcast push error:", pushError);
      }
    }
  } else {
    pushError = "FCM secrets not configured";
  }

  return json({
    ok: true,
    inserted,
    pushed,
    failed,
    pushError,
  });
});
