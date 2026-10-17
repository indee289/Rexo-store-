# Deep Link Test Matrix — Rexo Collab

These tests require a **device/emulator with the release (or debug) build
installed** and, for the HTTPS cases, a **deployed `assetlinks.json`** on the
production domain. They were **NOT run in the build sandbox** (no Flutter SDK /
emulator), so results are marked `NOT RUN` until executed on a device.

Setup:
```bash
PKG=com.rexo.marketplace
HOST=<PROD_DOMAIN>        # e.g. rexoagency.in (confirm before release)
```

Use a real, existing resource id/handle for "valid" cases and a random UUID for
the "invalid" case.

| # | Scenario | Command / action | Expected result | Status |
|---|----------|------------------|-----------------|--------|
| A | Installed + logged **out** + campaign link | `adb shell am start -a android.intent.action.VIEW -d "rexo://app/campaigns/<ID>" $PKG` | App opens → login (destination preserved) → after login lands on **campaign details `<ID>`**, not Home | NOT RUN |
| B | Installed + logged **in** + campaign link | same as A while signed in | Opens **campaign details `<ID>`** directly | NOT RUN |
| C | Creator profile link | `adb shell am start -a android.intent.action.VIEW -d "rexo://app/profile/<HANDLE>"` | Opens the public profile for `<HANDLE>` | NOT RUN |
| D | Chat/conversation link | `adb shell am start -a android.intent.action.VIEW -d "rexo://app/messages/<USER_ID>"` | Opens the chat with `<USER_ID>` (messages load under RLS) | NOT RUN |
| E | Invalid / nonexistent resource | `... -d "rexo://app/campaigns/00000000-0000-0000-0000-000000000000"` and a bad path `... -d "rexo://app/not-a-route"` | Bad **resource** → screen's not-found/empty state (RLS-safe). Bad **route** → "Link not found" screen with Go to Home | NOT RUN |
| F | HTTPS App Link | `adb shell am start -a android.intent.action.VIEW -d "https://$HOST/campaigns/<ID>"` | After verification: opens in app on campaign details. Before verification: browser/chooser (safe fallback) | NOT RUN |
| G | Custom scheme fallback | any `rexo://app/...` link above | Always opens the app (no domain verification needed) | NOT RUN |
| H | Cold start (app not running) | kill app, then run any case above | App launches straight to the target (deep link is the initial route) | NOT RUN |
| I | Warm start (app in background) | background the app, then run a link | App foregrounds and navigates to the target | NOT RUN |
| J | App already running (foreground) | run a link while app is open | Navigates to the target without restarting | NOT RUN |

### App Links verification (for cases F)
```bash
adb shell pm verify-app-links --re-verify com.rexo.marketplace
adb shell pm get-app-links com.rexo.marketplace     # domain must show "verified"
```

### Notes
- Cases A–J exercise the routes that actually exist. There is **no recovery
  route** in the codebase, so no recovery deep link is tested (see APP_LINKS.md).
- Security: none of these cases grant access via link parameters — each screen
  re-fetches under Supabase RLS, so an unauthorized resource link yields an
  empty/not-found state, never another user's data.
