# Campster — Google Play Console readiness checklist

`[x]` means verified from source configuration. Items that require the newly
built artifact or Play Console remain unchecked until the workflow/user verifies
them.

## Android build and signing

- [x] `applicationId`: `com.rexo.marketplace` (must match the existing Play app).
- [x] `minSdk 24` (Android 7.0+; satisfies Play Automatic Protection shown in the upload error).
- [x] `compileSdk 36` and `targetSdk 36` (required for new apps/updates from 31 August 2026).
- [x] Java/Kotlin 17, AGP 8.9.1, Gradle 8.11.1.
- [x] JNI libraries use extracted/legacy loading for API-24 device compatibility; CI still verifies arm64 and 16 KB artifact alignment.
- [x] Source version bumped to `1.0.2+3`; CI gives each artifact a unique increasing version code.
- [x] Release Gradle tasks fail if real signing material is absent—no debug fallback.
- [x] CI validates the keystore password/alias and proves the AAB certificate matches that keystore.
- [x] CI rejects the wrong min/target SDK, absent arm64, unsigned/debug AABs, and failed 16 KB APK alignment.
- [ ] Latest `Flutter Build` run is green on the release commit.
- [ ] Download `Campster-release-aab`, extract the ZIP, and upload `Campster.aab` (not the artifact ZIP).
- [ ] Confirm `release-info.txt` signer SHA-256 equals Play Console → App integrity → Upload key certificate.
- [ ] Enable Play App Signing (recommended).

## Public URLs

- [x] Website: `https://indee289.github.io/Rexo-store-/`
- [x] Privacy policy source: `privacy.html`
- [x] Account deletion source: `docs/account-deletion.html`
- [ ] Confirm both deployed URLs return HTTP 200 without login:
  - `https://indee289.github.io/Rexo-store-/privacy.html`
  - `https://indee289.github.io/Rexo-store-/docs/account-deletion.html`
- [ ] Paste those two URLs into Play Console.

## Play Console declarations

- [ ] Complete Data safety using `store/PLAY_STORE_LISTING.md` as the draft; verify every answer against production.
- [ ] Set target audience to 18+ and complete IARC content rating.
- [ ] Declare **No ads** if the release still contains no advertising.
- [ ] Complete financial-features declaration for campaign earnings/withdrawals.
- [ ] Provide reviewer/demo login credentials because core screens require authentication.
- [ ] Add testers and satisfy the applicable closed-testing requirement.
- [ ] Review the pre-launch report for crashes, ANRs, accessibility, and security warnings.

## Store listing assets

- [x] Campster listing copy and support email are prepared in `store/PLAY_STORE_LISTING.md`.
- [x] Android app label is `Campster`.
- [ ] Upload 2–8 real phone screenshots.
- [ ] Upload a 512×512 Play icon.
- [x] Campster 1024×500 feature graphic exists and has been visually inspected (`store/assets/feature_graphic.png`).

## Backend/runtime checks

- [x] CI refuses to build a production artifact when required Supabase, R2, Firebase, or signing configuration is missing/invalid.
- [ ] Run the account-deletion migration/Edge Function against production and test deletion end-to-end.
- [ ] Test sign-up/login, image upload/display, push notifications, campaign application, chat, and withdrawal on the exact closed-test AAB.
- [ ] Confirm production RLS/policies and deletion cascades have been applied.

A source/config audit can prevent known packaging mistakes, but only Play
Console and testing the generated AAB can confirm all account-specific policy
forms and runtime behavior.
