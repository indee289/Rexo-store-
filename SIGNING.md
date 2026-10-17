# Rexo Collab — Android Release Signing

This document describes how to produce a **production-signed** Android App
Bundle (`.aab`) for Google Play. The build is configured to **refuse** to
produce a release artifact unless real signing material is supplied — it will
never silently fall back to the debug keystore.

## 1. Generate an upload keystore (one time)

```bash
keytool -genkey -v \
  -keystore rexo-release.jks \
  -alias rexo \
  -keyalg RSA -keysize 2048 -validity 10000
```

Store `rexo-release.jks` **outside** the repository (or anywhere git-ignored)
and back it up securely. If you lose it you cannot ship updates unless you are
enrolled in Google Play App Signing (recommended — see §5).

## 2. Provide signing material

The Gradle config (`android/app/build.gradle`) resolves signing values from two
sources, in this priority order:

### Option A — Environment variables (recommended for CI)

| Variable | Meaning |
|---|---|
| `REXO_KEYSTORE_PATH` | Absolute path to the `.jks`/`.keystore` file |
| `REXO_KEYSTORE_PASSWORD` | Keystore (store) password |
| `REXO_KEY_ALIAS` | Key alias (e.g. `rexo`) |
| `REXO_KEY_PASSWORD` | Key password |

### Option B — `android/key.properties` (recommended for local machines)

Copy `android/key.properties.example` → `android/key.properties` and fill in:

```properties
storeFile=/absolute/path/to/rexo-release.jks
storePassword=...
keyAlias=rexo
keyPassword=...
```

Both `key.properties` and `*.jks`/`*.keystore` are already listed in
`.gitignore`. **Never commit them.**

## 3. Build the production AAB

```bash
# from the repository root
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=R2_PUBLIC_URL=... \
  --dart-define=ONESIGNAL_APP_ID=...
```

Output: `build/app/outputs/bundle/release/app-release.aab`

If signing material is missing, the build stops with a clear
`RELEASE SIGNING NOT CONFIGURED` error rather than emitting a debug-signed file.

## 4. Verify the signature of the produced artifact

```bash
# Inspect the AAB's signing block (requires Android build-tools):
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/release/app-release.aab

# Or, for an APK produced from the bundle:
apksigner verify --print-certs app-release.apk
```

Confirm the certificate is the **release** cert (your alias), not
`CN=Android Debug`.

## 5. Google Play App Signing (recommended)

Enroll the app in Play App Signing. You upload with your *upload key*
(the keystore above); Google re-signs with the *app signing key* it manages.
This protects you against upload-key loss.

## Notes

- `applicationId`: `com.rexo.marketplace`
- `versionName` / `versionCode`: derived from `pubspec.yaml`
  (`version: 1.0.0+1` → versionName `1.0.0`, versionCode `1`). Bump the `+N`
  build number for every Play upload.
