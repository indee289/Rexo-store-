# send-broadcast Edge Function

Authoritative path for admin broadcasts. It does **both**:

1. Inserts one in-app `notifications` row per target user (service role → bypasses RLS).
2. Delivers a real **FCM push (HTTP v1)** to each target user's registered devices
   (`user_devices.fcm_token`), minting a Google OAuth2 access token by RS256-signing
   a JWT with the Firebase service-account private key (Deno Web Crypto).

The Flutter client calls it via `functions.invoke('send-broadcast', body: {title, message})`
and **does not** insert notification rows itself (avoids duplicates).

## Security

- Requires the caller's Supabase JWT (`Authorization: Bearer <token>`, attached
  automatically by `functions.invoke`).
- Verifies the caller has `users.role = 'admin'`; otherwise returns `403`.
- The service-account private key lives only in Edge Function secrets — never in
  the app bundle.

## Deploy (NEEDS-USER-ACTION)

Run from the repo root with the Supabase CLI (`supabase login` + `supabase link`
already done):

```bash
# 1) Set FCM secrets (values come from the Firebase service-account JSON:
#    Project Settings -> Service accounts -> Generate new private key)
supabase secrets set \
  FCM_PROJECT_ID="your-firebase-project-id" \
  FCM_CLIENT_EMAIL="firebase-adminsdk-xxxx@your-project.iam.gserviceaccount.com" \
  FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# 2) Deploy
supabase functions deploy send-broadcast
```

Notes:

- `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically for
  deployed functions — do not set them manually.
- The function accepts the private key in any of these shapes (it normalizes to PKCS8):
  a normal PEM, a PEM with literal `\n` escapes, the whole Firebase service-account
  JSON (project id / client email are read from it too), base64 of any of those, or
  just the base64 key body with the `BEGIN/END PRIVATE KEY` lines missing.
  A `BEGIN RSA PRIVATE KEY` (PKCS1) key is still rejected — convert it with
  `openssl pkcs8 -topk8 -nocrypt`.

## Response

```json
{ "ok": true, "inserted": 42, "pushed": 30, "failed": 2, "pushError": null }
```

If FCM secrets are absent, notifications are still inserted and `pushError` explains
that push was skipped (best-effort).
