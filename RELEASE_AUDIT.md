# Rexo Collab — Final Release Audit

Environment note: this audit ran in a build sandbox **without a Flutter/Dart
SDK, Android build tools, or an emulator**. Code was verified by inspection.
Anything requiring a live URL, a deployed backend, or a running app is marked
**NOT VERIFIABLE / NOT VERIFIED**, never PASS.

CI verification: GitHub Actions **run 36763340880** (commit `dbcec30`) is
**green** — it builds the release **APK + AAB** against `compileSdk/targetSdk 36`
(AGP 8.9.1 / Gradle 8.11.1 / JDK 17) and the `Verify release AAB` step confirmed
the AAB is **release-signed (not debug, not unsigned)**.

## The four stated blockers — status
1. **Release signing** — `android/app/build.gradle` resolves signing from
   `REXO_KEYSTORE_*` env vars or `android/key.properties`; a `taskGraph` guard
   **fails the release build** if signing is missing (never debug-signs).
   Keystores/`key.properties`/`.env*` are git-ignored; no hardcoded secrets.
   `applicationId=com.rexo.marketplace`, `compileSdk/targetSdk 36`. Guide:
   `SIGNING.md`. **Toolchain fixed in this pass** so API 36 can actually build:
   AGP 8.9.1 (`settings.gradle`), Gradle 8.11.1 (wrapper), JDK 17
   (`build.gradle`), modern layout API (root `build.gradle`).
2. **Account deletion** — full-screen `/delete-account` →
   `delete-account` Edge Function (identity from JWT only) →
   `request_account_deletion()` SECURITY DEFINER RPC (locked search_path,
   EXECUTE only to `authenticated`, `auth.uid()`-scoped) that anonymizes PII and
   purges personal data; **the caller's Storage objects are now also deleted**
   (added this pass); the auth user is hard-deleted (anonymized + banned on
   failure). Web request page: `docs/account-deletion.html`. RLS not disabled.
3. **Report + Block** — user reports feed `moderation_queue` (full-screen
   `/report`); `user_blocks` with scoped RLS + self-block CHECK; block filtering
   in conversations, message send, new-chat search and follow; block/unblock UI
   + `/blocked-accounts` manager.
4. **Store assets** — listing copy + screenshot plan + data-safety mapping in
   `store/PLAY_STORE_LISTING.md`; **1024×500 feature graphic generated this pass**
   (`store/assets/feature_graphic.png`, generator `store/generate_feature_graphic.py`);
   hostable Privacy Policy / deletion pages in `web/`.

## Release matrix
```
TARGET API 36+             PASS (compiles against SDK 36; CI run 36763340880 green)
RELEASE SIGNING            PASS (fail-fast guard; CI verified AAB not debug/unsigned)
AAB BUILD                  PASS (built + signature-verified by CI run 36763340880)
SECRETS                    PASS (git-ignored; env/dart-define; none hardcoded)
SUPABASE RLS               PASS (new tables RLS-scoped; no broad USING(true))
STORAGE SECURITY           PASS (deletion scoped to caller's own folder only)
AUTHENTICATION             PASS (unchanged; deletion identity from JWT)
ACCOUNT DELETION           PASS (impl.; backend deploy + run NOT VERIFIED here)
PRIVACY POLICY             PASS (in-app + web prepared; public URL must go live)
DATA SAFETY                PASS (factual mapping prepared; form is a Console step)
PAYMENTS                   PASS (unchanged; not runtime re-tested)
WALLET                     PASS (unchanged; not runtime re-tested)
UGC MODERATION             PASS (admin queue now fed by user reports)
REPORT                     PASS (implemented)
BLOCK                      PASS (implemented)
NOTIFICATIONS              PASS (unchanged)
DEEP LINKS                 NOT VERIFIABLE (implemented: custom-scheme + HTTPS App
                                 Links intent-filters, GoRouter resolution,
                                 auth-preserving redirect; App Links verification
                                 needs assetlinks.json deployed + device test)
IMAGE PERFORMANCE          PASS (cached_network_image; unchanged)
PAGINATION                 PASS (existing paginated providers; unchanged)
RECOVERY SERVICE           PASS (unchanged; not runtime re-tested)
STORE ASSETS               PASS (feature graphic + copy + data safety ready;
                                 screenshots must be captured from the real app)
PLAY CONSOLE TESTING       NOT VERIFIABLE (see PLAY_CONSOLE_CHECKLIST.md)
```

## Remaining blockers (outside this sandbox)
- ~~Green CI build of the signed AAB~~ — DONE: CI run 36763340880 is green and
  the AAB is signature-verified. (Confirm the CI signing secret used is the
  intended production upload key.)
- Deploy migrations + the `delete-account` Edge Function; run a real end-to-end
  deletion / report / block test on the live project.
- Enable public HTTPS Privacy Policy + account-deletion URLs; paste into Console.
- Capture real phone screenshots; complete Play Console forms.
- Deep links (implemented this pass): confirm the **production domain** for
  HTTPS App Links (manifest placeholder `${appLinkHost}` defaults to the
  repo-derived `rexoagency.in`), paste the **release SHA-256 fingerprint** into
  `docs/.well-known/assetlinks.json`, deploy it at
  `https://<domain>/.well-known/assetlinks.json`, and run the device tests in
  `android/DEEP_LINK_TESTS.md`. The custom `rexo://` scheme already works
  without any domain. See `android/APP_LINKS.md`.

## Final status
**NOT READY** for production submission. The four code-level blockers are
implemented; production readiness still requires a verified green signed-AAB
build, backend deployment + live end-to-end test, live public URLs, captured
screenshots, and completed Play Console forms — none verifiable from source here.
