# Campster — Android release audit

Updated: October 13, 2026.

## Source-controlled release status

| Check | Status | Evidence |
|---|---|---|
| Application ID | Configured | `com.rexo.marketplace` in `android/app/build.gradle` |
| Minimum Android API | Fixed | `minSdk 24` (Android 7.0+) |
| Play target/compile API | Configured | `targetSdk 36`, `compileSdk 36` |
| Release version | Bumped | source `1.0.2+3`; CI uses unique `10000 + run number` version codes |
| Release signing | Fail-closed | release tasks refuse missing signing inputs and never use the debug key |
| Keystore validation | Configured | workflow validates Base64, password, alias and file integrity |
| AAB signer verification | Configured | `jarsigner` must succeed and AAB SHA-256 must match the configured keystore |
| Play upload-key pinning | Optional | enforced when `ANDROID_UPLOAD_CERT_SHA256` is configured |
| 64-bit | CI-enforced | AAB must contain `arm64-v8a` libraries |
| Native packaging | Compatibility mode | compressed/extracted JNI loading avoids the API-24 OEM launch regression; CI retains arm64/16 KB checks |
| Runtime configuration | CI-enforced | build fails when production Supabase/R2/Firebase configuration is absent or invalid |
| Product branding | Aligned | Campster in Android labels, localization, legal/store docs and graphics |
| Feature graphic | Prepared | `store/assets/feature_graphic.png`, 1024×500 RGB PNG |
| Privacy/deletion pages | Prepared | public-page sources and exact URLs in `PLAY_CONSOLE_CHECKLIST.md` |

## Verification boundary

No Flutter/Android toolchain or keystore secret is available in this sandbox.
The workflow YAML, embedded shell scripts, Gradle delimiter/config invariants,
brand strings, and artifact dimensions were statically checked here. The new
release artifact is not considered verified until the automatic GitHub Actions
run completes successfully.

When green, download `Campster-release-aab`, extract `Campster.aab`, and upload
that file—not GitHub's artifact ZIP. Keep `release-info.txt` and compare its
`signerSha256` with the upload certificate in Play Console → App integrity.

## Console/runtime work that source code cannot complete

- Complete Data safety, content rating, target audience, ads and financial
  features declarations.
- Add closed-test users and reviewer login credentials.
- Confirm the public privacy and account-deletion URLs load without login.
- Test the exact AAB on a closed track: authentication, campaign/application,
  messages, notifications, image upload/display, wallet withdrawal, report,
  block and account deletion.
- Review Play's pre-launch report and App Bundle Explorer (including 16 KB page
  compatibility) before promoting the release.

See `PLAY_CONSOLE_CHECKLIST.md` and `SIGNING.md` for the exact steps.
