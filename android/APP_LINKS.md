# Android App Links & Deep Linking — Rexo Collab

This app supports two kinds of deep links (see `AndroidManifest.xml`):

1. **Custom scheme (fallback, always works):** `rexo://<host>/<path>`
   The host is ignored; GoRouter matches on the **path**. Example:
   `rexo://app/campaigns/123` → `/campaigns/:id`.
2. **HTTPS App Links (Android-verified):** `https://<PROD_DOMAIN>/<path>`
   Opened directly in the app **only after** verification succeeds against a
   deployed `assetlinks.json`.

## ⚠️ Requires production configuration before release (outside the repo)

- **Production domain is NOT confirmed in the repo.** The manifest host is a
  build placeholder `${appLinkHost}`, defaulting to `rexoagency.in` (the only
  domain present in the repo — the contact/privacy email domain). **Confirm the
  real production domain** and, if different, set it at build time:
  ```bash
  flutter build appbundle --release -PrexoAppLinkHost=links.yourdomain.com
  # or: export REXO_APP_LINK_HOST=links.yourdomain.com
  ```
- **Package name:** `com.rexo.marketplace` (from `android/app/build.gradle`
  `applicationId`).
- **Release SHA-256 fingerprint:** obtain from the release/upload key and paste
  it into `docs/.well-known/assetlinks.json` (replace
  `REPLACE_WITH_RELEASE_SHA256_FINGERPRINT`). If you use **Play App Signing**,
  use the **App signing key** SHA-256 shown in Play Console → Setup → App
  integrity (add the upload key fingerprint too).
  ```bash
  # From the keystore:
  keytool -list -v -keystore <release-keystore.jks> -alias <alias> | grep SHA256
  # From an APK/AAB:
  apksigner verify --print-certs app-release.aab | grep -i sha-256
  ```
- **Deploy `assetlinks.json`** at exactly:
  `https://<PROD_DOMAIN>/.well-known/assetlinks.json`
  (public, HTTPS, `Content-Type: application/json`, HTTP 200, no redirect, no
  auth). The file in `docs/.well-known/assetlinks.json` can be served via GitHub
  Pages or copied to your host. If you support `www.`, serve it there too.
- **Verify** after deployment:
  ```bash
  # Google Digital Asset Links API:
  curl "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://<PROD_DOMAIN>&relation=delegate_permission/common.handle_all_urls"
  # On a device with the release build installed:
  adb shell pm verify-app-links --re-verify com.rexo.marketplace
  adb shell pm get-app-links com.rexo.marketplace   # expect: verified
  ```

Until the above is done, App Links **verification cannot be claimed**. The
custom `rexo://` scheme still opens the app in the meantime.

## Route ↔ deep link map (paths mirror GoRouter)

| Purpose            | Path                    | Example App Link / custom scheme                         |
| ------------------ | ----------------------- | -------------------------------------------------------- |
| Home               | `/home`                 | `https://<host>/home` · `rexo://app/home`                |
| Creator profile    | `/creators/:id`         | `https://<host>/creators/<uuid>` · `rexo://app/creators/<uuid>` |
| Public profile     | `/profile/:handle`      | `https://<host>/profile/<handle>` · `rexo://app/profile/<handle>` |
| Campaign details   | `/campaigns/:id`        | `https://<host>/campaigns/<uuid>` · `rexo://app/campaigns/<uuid>` |
| Chat / conversation| `/messages/:userId`     | `https://<host>/messages/<uuid>` · `rexo://app/messages/<uuid>` |
| Privacy policy     | `/privacy-policy`       | `https://<host>/privacy-policy`                          |
| Account deletion   | `/settings/delete-account` (auth) | `https://<host>/settings/delete-account`       |

> **Recovery:** the repository has **no** recovery route/screen implemented
> (only `disputes` and `services`). No recovery deep link is defined; add one
> here if/when a recovery feature is built. No fake route was created to pass
> the audit.

## Authenticated routes
Deep links to protected routes while logged out are **not** dropped on Home:
`app_router.dart` captures the intended location in `_pendingDeepLink`, sends
the user through login (and MFA if enabled), then returns them to the original
destination. See `redirect` in `lib/core/router/app_router.dart`.

## Security
A deep link only **identifies** a resource; it never grants access. Every
destination screen loads its data through Supabase with **RLS enforced**
(e.g. `/campaigns/:id`, `/messages/:userId`, `/profile/:handle`), so a user who
opens a link to a resource they may not view gets an empty/not-found state, not
unauthorized data. No authorization decision is made from link parameters.
