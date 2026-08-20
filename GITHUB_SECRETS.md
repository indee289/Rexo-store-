# Rexo Influencer Marketplace - GitHub Secrets & Security Documentation

This document specifies the exact GitHub Repository Secrets required to automate Supabase Edge Function deployments, secret synchronization, and Android Release APK distribution.

---

## 🔑 Complete GitHub Secrets Reference Checklist

| GitHub Secret Name | Source / Provider | Service Used By | Required / Optional | Target Location |
| :--- | :--- | :--- | :--- | :--- |
| `SUPABASE_ACCESS_TOKEN` | Supabase Dashboard -> Account -> Access Tokens | GitHub Actions CI/CD CLI | **Required** | GitHub Actions Secret |
| `SUPABASE_PROJECT_ID` | Supabase Dashboard -> Project Settings | Supabase Link & Secrets Sync | **Required** | GitHub Actions Secret |
| `VITE_SUPABASE_URL` | Supabase Dashboard -> API Settings | Frontend Client Build | **Required** | Client Public Bundle |
| `VITE_SUPABASE_ANON_KEY` | Supabase Dashboard -> API Settings | Frontend Client Build | **Required** | Client Public Bundle |
| `R2_ACCOUNT_ID` | Cloudflare Dashboard -> R2 -> Overview | `r2-upload`, `r2-download` Edge Functions | **Required** | Supabase Edge Secrets |
| `R2_ACCESS_KEY_ID` | Cloudflare Dashboard -> R2 -> API Tokens | `r2-upload`, `r2-download` Edge Functions | **Required** | Supabase Edge Secrets |
| `R2_SECRET_ACCESS_KEY` | Cloudflare Dashboard -> R2 -> API Tokens | `r2-upload`, `r2-download` Edge Functions | **Required** | Supabase Edge Secrets |
| `R2_BUCKET_NAME` | Cloudflare Dashboard -> R2 -> Bucket Name | `r2-upload`, `r2-download` Edge Functions | **Required** | Supabase Edge Secrets |
| `GEMINI_API_KEY` | Google AI Studio -> API Keys | `ai-moderation` Edge Function | **Required** | Supabase Edge Secrets |
| `FCM_PROJECT_ID` | Firebase Console -> Project Settings | `push-notification` Edge Function | Optional | Supabase Edge Secrets |
| `FCM_CLIENT_EMAIL` | Firebase Service Account JSON (`client_email`) | `push-notification` Edge Function | Optional | Supabase Edge Secrets |
| `FCM_PRIVATE_KEY` | Firebase Service Account JSON (`private_key`) | `push-notification` Edge Function | Optional | Supabase Edge Secrets |
| `PAYMENT_SECRET_KEY` | Razorpay / Stripe / Payment Gateway Dashboard | `payment` Edge Function | Optional | Supabase Edge Secrets |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 upload-keystore.jks` | Android Release Signing | Optional | GitHub Actions Secret |
| `ANDROID_KEYSTORE_PASSWORD` | Java Keytool Generation Password | Android Release Signing | Optional | GitHub Actions Secret |
| `ANDROID_KEY_ALIAS` | Java Keytool Alias Name | Android Release Signing | Optional | GitHub Actions Secret |
| `ANDROID_KEY_PASSWORD` | Java Keytool Key Password | Android Release Signing | Optional | GitHub Actions Secret |

---

## 🛡️ Architecture & Security Rules

1. **Zero-Secret Client Policy**:
   * No secret credentials (`R2_SECRET_ACCESS_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, `FCM_PRIVATE_KEY`, etc.) are ever present in client-side code, `.env.example`, or the compiled APK bundle.
   * All privileged operations (R2 upload URL generation, R2 download URL generation, AI moderation, push notifications, wallet transaction approvals, and admin state updates) run inside isolated Supabase Edge Functions.

2. **Supabase Edge Function Deployment**:
   * Edge Functions can be deployed manually via Supabase CLI or automatically via GitHub Actions:
     ```bash
     supabase secrets set R2_ACCOUNT_ID="your_id" R2_ACCESS_KEY_ID="your_key" R2_SECRET_ACCESS_KEY="your_secret" R2_BUCKET_NAME="your_bucket" GEMINI_API_KEY="your_gemini_key" --project-ref "your_project_id"
     supabase functions deploy r2-upload --no-verify-jwt
     supabase functions deploy r2-download --no-verify-jwt
     supabase functions deploy ai-moderation --no-verify-jwt
     supabase functions deploy push-notification --no-verify-jwt
     supabase functions deploy payment --no-verify-jwt
     supabase functions deploy admin --no-verify-jwt
     ```

3. **Android Release APK Distribution**:
   * The GitHub Actions workflow `.github/workflows/build-android-release.yml` triggers on release tag pushes (e.g. `v1.0.0`) or manual workflow dispatch.
   * The compiled release APK is attached directly to **GitHub Releases -> Assets** (`Rexo-Influencer-Marketplace-v1.0.0-release.apk`).
