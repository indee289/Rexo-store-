# Campster — Android release signing

Campster release builds are configured to fail instead of creating an unsigned
or debug-signed APK/AAB. The Play application ID is immutable:
`com.rexo.marketplace`.

## GitHub Actions (recommended)

Add these Actions secrets in **Repository Settings → Secrets and variables →
Actions**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the complete upload `.jks`/`.keystore` file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Upload-key alias |
| `ANDROID_KEY_PASSWORD` | Alias/private-key password |
| `GOOGLE_SERVICES_JSON` | Real Firebase JSON, either raw JSON or base64 |
| `SUPABASE_URL` | Production Supabase HTTPS URL |
| `SUPABASE_ANON_KEY` | Production Supabase anon/publishable key |
| `R2_ACCESS_KEY_ID` | Current R2 access-key ID |
| `R2_SECRET_ACCESS_KEY` | Current R2 secret key |
| `R2_ACCOUNT_ID` | R2 account ID |
| `R2_BUCKET_NAME` | R2 bucket name |
| `R2_PUBLIC_URL` | Public HTTPS base URL for uploaded images |
| `ONESIGNAL_APP_ID` | OneSignal app ID (optional; the app has a public default) |
| `ANDROID_UPLOAD_CERT_SHA256` | Optional but recommended: Play Console upload-certificate SHA-256 |

Legacy `REXO_KEYSTORE_BASE64`, `REXO_KEYSTORE_PASSWORD`, `REXO_KEY_ALIAS`, and
`REXO_KEY_PASSWORD` names are accepted as signing fallbacks. The workflow:

1. verifies that every required value exists;
2. decodes the keystore only into the ephemeral GitHub runner;
3. proves that its password and alias are valid;
4. builds release APK and AAB with that keystore;
5. verifies the AAB signature and confirms its certificate matches the supplied
   keystore (and `ANDROID_UPLOAD_CERT_SHA256` when configured);
6. checks merged min/target SDK values, arm64 support, and 16 KB APK alignment;
7. uploads `Campster.aab` and `release-info.txt` in the
   `Campster-release-aab` workflow artifact.

GitHub wraps workflow artifacts in a ZIP. Extract `Campster.aab` from that ZIP
before uploading it to Play Console.

To encode a keystore locally without line wrapping:

```bash
base64 -w 0 campster-upload.jks > campster-upload.jks.base64
```

Do not commit either file.

## Local release build

The Gradle config can also read these environment variables:

- `REXO_KEYSTORE_PATH` (prefer an absolute path)
- `REXO_KEYSTORE_PASSWORD`
- `REXO_KEY_ALIAS`
- `REXO_KEY_PASSWORD`

Alternatively copy `android/key.properties.example` to
`android/key.properties` and fill it in. Both the properties file and keystores
are git-ignored.

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=R2_ACCESS_KEY_ID=... \
  --dart-define=R2_SECRET_ACCESS_KEY=... \
  --dart-define=R2_ACCOUNT_ID=... \
  --dart-define=R2_BUCKET_NAME=... \
  --dart-define=R2_PUBLIC_URL=...
```

The source version is `1.0.2+3`; GitHub Actions overrides only the version code
with a unique increasing value (`10000 + workflow run number`) so successive
Play artifacts cannot accidentally reuse code `1`.

## Play App Signing

Enroll in Play App Signing. Campster is uploaded with your **upload key** and
Google distributes APKs signed with the separate **app-signing key**. Compare
the upload certificate shown under **Play Console → App integrity** with
`signerSha256` in `release-info.txt`. Adding that value as
`ANDROID_UPLOAD_CERT_SHA256` makes CI enforce the match automatically.
