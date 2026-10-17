# Rexo Collab — Google Play Console Readiness Checklist

Legend: `[x] VERIFIED` = confirmed by an artifact in this repo (file/config).
`[ ] NOT VERIFIED` = requires a build, a design asset, or Play Console access
that cannot be confirmed from source code. **Nothing is marked VERIFIED without
evidence in-repo.**

> Source-code work is complete for the four release blockers. Everything that
> depends on the Google Play Console, a real keystore, a Flutter build, or a
> design tool is listed as NOT VERIFIED with the exact action required.

---

## Build & signing
- [x] VERIFIED — Target API level 36 (`android/app/build.gradle`: `compileSdk 36`, `targetSdk 36`, `minSdk 21`).
- [x] VERIFIED — Release signing configured from env vars **or** `key.properties`, with a hard failure (no silent debug fallback) — `android/app/build.gradle` + `SIGNING.md` + `android/key.properties.example`.
- [x] VERIFIED — Secrets are git-ignored (`.gitignore`: `key.properties`, `*.jks`, `*.keystore`, `*.aab`, `.env*`, `google-services.json`).
- [ ] NOT VERIFIED — **Release AAB built.** Action: provide keystore, then
  `flutter build appbundle --release` with required `--dart-define`s (see SIGNING.md).
  (No Flutter SDK in this environment.)
- [ ] NOT VERIFIED — **AAB signature verified** against the release cert
  (`jarsigner -verify` / `apksigner verify --print-certs`).
- [ ] NOT VERIFIED — Google Play App Signing enrolled.

## App content / policy declarations (Play Console)
- [ ] NOT VERIFIED — Privacy Policy URL set (host `docs/privacy-policy.html` publicly; paste HTTPS URL).
- [ ] NOT VERIFIED — Account deletion URL set (host `docs/account-deletion.html` publicly; paste HTTPS URL).
- [x] VERIFIED — In-app account deletion exists (Settings → Delete Account → `/settings/delete-account`, RPC `request_account_deletion` + Edge Function).
- [ ] NOT VERIFIED — Data Safety form completed & submitted (draft mapping in `store/PLAY_STORE_LISTING.md` §E).
- [ ] NOT VERIFIED — Content rating (IARC questionnaire) completed.
- [ ] NOT VERIFIED — Target audience set to 18+ (app states 18+).
- [ ] NOT VERIFIED — Ads declaration (app currently serves no ads — declare "No").
- [ ] NOT VERIFIED — Government-apps / financial-features declarations as prompted (app has wallet/payments).
- [ ] NOT VERIFIED — News/COVID/health declarations (N/A — confirm "No").

## Store listing
- [x] VERIFIED — Listing copy drafted (`store/PLAY_STORE_LISTING.md`): app name, short & full description, category, contacts.
- [ ] NOT VERIFIED — App name/short/full description entered in Console.
- [ ] NOT VERIFIED — Screenshots (2–8 phone) captured per the plan in `store/PLAY_STORE_LISTING.md` §B. (Needs a build + capture.)
- [ ] NOT VERIFIED — Feature graphic 1024×500 created & uploaded (spec in §C; needs a design tool).
- [ ] NOT VERIFIED — Marketing app icon 512×512 uploaded (derive from launcher icon).
- [ ] NOT VERIFIED — App category & tags selected.
- [ ] NOT VERIFIED — Contact email/website entered.

## Testing tracks
- [ ] NOT VERIFIED — Production app created in Play Console.
- [ ] NOT VERIFIED — Internal testing track configured.
- [ ] NOT VERIFIED — Closed testing track configured + testers added.
- [ ] NOT VERIFIED — Pre-launch report reviewed (no blocking crashes).
- [ ] NOT VERIFIED — App access / reviewer test credentials provided (login required — give a demo account).

## Backend prerequisites (Supabase) — must run before release
- [ ] NOT VERIFIED — Apply `supabase/migrations/20260921_account_deletion.sql` to the LIVE DB and review NOTICE output.
- [ ] NOT VERIFIED — Apply `supabase/migrations/20260921_reports_and_blocks.sql` to the LIVE DB.
- [ ] NOT VERIFIED — Deploy Edge Function: `supabase functions deploy delete-account`.
- [ ] NOT VERIFIED — Manually test: report insert, block/unblock, and `request_account_deletion()` as a real authenticated user.

## Runtime config (dart-define at build)
- [ ] NOT VERIFIED — `SUPABASE_URL`, `SUPABASE_ANON_KEY` supplied.
- [ ] NOT VERIFIED — `R2_PUBLIC_URL` (image rendering), `ONESIGNAL_APP_ID` supplied.
- [ ] NOT VERIFIED — `google-services.json` present for FCM (git-ignored; add at build).

---

### Summary
All **source-controlled** blockers are implemented and verifiable in-repo
(signing config, in-app + web account deletion, report, block, listing copy,
privacy/deletion web pages). The remaining unchecked items require a keystore,
a Flutter build, design binaries, a live Supabase migration/deploy, or Play
Console access, and are therefore **NOT VERIFIED** here by design.
