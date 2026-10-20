# Campster — Google Play Store Listing (Draft Copy + Asset Plan)

> All copy below is written to be **factual and verifiable against the shipped
> app**. Do NOT add claims about user counts, brand counts, partnerships,
> certifications, Meta/Instagram affiliation, or guaranteed outcomes unless
> they are independently verifiable. Placeholders are marked `<<LIKE THIS>>`.

---

## A. Store listing copy

### App name (≤ 30 chars)
`Campster` (8 chars)

### Short description (≤ 80 chars)
`Connect creators and brands for influencer marketing campaigns.` (63 chars)

### Full description (≤ 4000 chars)
```
Campster is an influencer-marketing marketplace that connects content
creators with brands running promotional campaigns.

FOR CREATORS
• Browse active campaigns and jobs and filter by category and platform.
• Apply to campaigns that match your niche and audience.
• Track your applications and submissions in one place.
• Build a public creator profile with your bio and social handles.
• Follow other creators and message brands and creators directly.
• Manage earnings in an in-app wallet and request withdrawals.

FOR BRANDS
• Create and publish campaigns with budgets, slots and requirements.
• Review creator applications and manage participants.
• Communicate with creators through in-app chat.

SAFETY & CONTROL
• Report users, campaigns or messages that violate our guidelines.
• Block accounts you don't want to interact with.
• Two-factor authentication (TOTP) and active-session management.
• Delete your account and personal data at any time from Settings.

Eligible campaign earnings can be credited to the in-app wallet and withdrawn.
Amounts shown are in Indian Rupees (INR).

Campster is intended for users aged 18 and over.

Questions or support: rexoagency.in@gmail.com
Privacy: rexoagency.in@gmail.com
```
> Trim/adjust before publishing. Every bullet corresponds to a feature present
> in the codebase (campaigns, jobs, applications, profiles, follow, messaging,
> wallet/withdrawals, report, block, 2FA, sessions, account deletion).

### Category
- **Application type:** App
- **Category:** Business  *(alternative: Social)*
- **Tags:** influencer marketing, creators, marketing

### Contact details
- **Email (required):** `rexoagency.in@gmail.com`  *(matches AppConstants.supportEmail)*
- **Phone (optional):** `<<OPTIONAL SUPPORT PHONE>>`
- **Website:** `https://indee289.github.io/Rexo-store-/`

### Required URLs
- **Privacy Policy URL:** `https://indee289.github.io/Rexo-store-/privacy.html`
  (public HTTPS page; no login)
- **Account deletion URL:** `https://indee289.github.io/Rexo-store-/docs/account-deletion.html`
  (public instructions for in-app and email deletion requests)

---

## B. Screenshots plan (phone)

**Google Play requirements (phone):** 2–8 screenshots, PNG or JPEG, 16:9 or 9:16,
each side between 320 px and 3840 px. Recommended: **1080 × 1920** (portrait).

Capture from a **debug/staging build with realistic (non-defamatory, non-PII)
sample data**. Every screen below is implemented in the app — do not stage
features that don't exist.

| # | Screen | Route / source file | Caption idea |
|---|--------|---------------------|--------------|
| 1 | Home / Dashboard | `/home` → `home_screen.dart` | "Discover campaigns and top creators" |
| 2 | Campaign marketplace | `/campaigns` → `campaigns_screen.dart` | "Browse active brand campaigns" |
| 3 | Campaign details | `/campaigns/:id` → `campaign_detail_screen.dart` | "See payout, slots and requirements" |
| 4 | Jobs list | `/jobs` → `jobs_screen.dart` | "Find paid creator jobs" |
| 5 | Creator profile | `/creators/:id` → `creator_profile_screen.dart` | "Showcase your creator profile" |
| 6 | Messages / Chat | `/messages/:userId` → `chat_screen.dart` | "Chat with brands and creators" |
| 7 | Wallet | `/wallet` → `wallet_screen.dart` | "Track earnings and withdrawals" |
| 8 | Settings (safety) | `/settings` → `settings_screen.dart` | "Control privacy, blocking and account deletion" |

> Admin/Moderation screens are staff-only — do NOT put them in the public listing.

**Feature-graphic-free tablet note:** tablet screenshots are optional; only add
them if you support tablet layouts.

---

## C. Feature graphic (required)

- **Size:** exactly **1024 × 500 px**, PNG or JPEG, no transparency.
- **Content guidance:**
  - Left: "Campster" wordmark + tagline "Creators × Brands".
  - Right: a clean device mock showing the campaigns screen.
  - Use the app's brand palette (see `lib/core/theme/app_colors.dart`,
    IG-style accent `#ED4956`, near-black text on white).
- **Avoid:** fake/AI-looking UI, heavy gradients, neon glow, oversized text,
  fake 3D, and any claim (numbers, logos of platforms you're not affiliated
  with, "official", etc.).
- **Verified asset:** `store/assets/feature_graphic.png` is a 1024×500,
  opaque RGB PNG branded Campster. Editable source: `store/feature_graphic.html`
  (the Python generator is retained as an alternate source).

> Inspect the final graphic visually before uploading it in Play Console.

### App icon (marketing) — 512 × 512 px
- 32-bit PNG, ≤ 1 MB. Derive from the existing launcher icon
  (`android/app/src/main/res/mipmap-*/ic_launcher.png`) at 512×512.

---

## D. Privacy Policy (verification checklist)

The app already contains an in-app policy
(`lib/features/legal/screens/privacy_policy_screen.dart`). For the Play Console
you also need a **public web URL**:

- [x] Hosted page source uses a public HTTPS GitHub Pages URL (confirm HTTP 200 after deployment).
- [x] Content matches the app's current Campster policy and support address.
- [x] Names the support/privacy contact (`rexoagency.in@gmail.com`).
- [x] States data retention (financial records retained per law; profile PII
      deleted/anonymized on account deletion).
- [x] Links to the account-deletion page.
- [x] In-app policy date is September 21, 2026; public policy is October 2026.

---

## E. Data Safety form — factual mapping

Base the Play Console Data Safety form on the ACTUAL implementation and SDKs
(Supabase auth/DB, Cloudflare R2 storage, Firebase Cloud Messaging, and OneSignal
push). Draft mapping:

| Data type | Collected | Shared | Purpose | Required? | Notes |
|---|---|---|---|---|---|
| Name | Yes | No | Account, profile | Required | `users.name` |
| Email address | Yes | No | Account, auth, support | Required | `users.email` (Supabase auth) |
| User IDs | Yes | No | Account, app functionality | Required | auth uid |
| Phone number | Yes* | No | Account/verification | Optional | if provided |
| Photos | Yes* | No | Profile / campaign assets | Optional | R2 storage |
| Social handles | Yes* | No | Campaign matching | Optional | linked accounts |
| Financial info (payout/UPI/bank) | Yes* | With payment processing | Payments/withdrawals | Optional | retained per law |
| Messages (in-app chat) | Yes | No | App functionality | Required for chat | `chat_messages` |
| App activity / interactions | Yes | No | App functionality, analytics | Required | |
| Device identifiers / push tokens | Yes | With FCM/OneSignal | Push notifications | Optional | FCM + OneSignal |
| Approximate/precise location | No | — | — | — | app does NOT request location |

Security & deletion declarations:
- [x] Data encrypted in transit (HTTPS/TLS to Supabase/R2).
- [x] Users can request data deletion (in-app: Settings → Delete Account;
      web: `account-deletion.html`).
- [x] Data retention: financial records retained for legal compliance,
      anonymized on deletion.

> `*` "Yes" only if the user actually provides it. Verify each row against the
> live database columns and enabled SDKs before submitting — the Data Safety
> declaration must be accurate.

---

## F. Content rating & audience
- Complete the **IARC content-rating questionnaire** in the Console.
- **Target audience:** 18+ (the Privacy Policy and app state 18+; do not target
  children). This affects the Data Safety and Families policy sections.

---

## G. What this repo CAN and CANNOT produce

- CAN (text/config, in-repo): listing copy, screenshot capture plan, Data
  Safety mapping, privacy/account-deletion web pages, signing config.
- CANNOT (needs a design tool + Play Console, done by a human):
  the 1024×500 feature graphic binary, the 512×512 marketing icon binary, the
  actual captured screenshot PNGs, and anything requiring Play Console access.
