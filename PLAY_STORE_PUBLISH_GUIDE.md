# Campster — Google Play par publish karne ki poori guide

Ye guide step-by-step batati hai ki Play Console mein **kaunse option mein kya
select/fill karna hai**. Jahan "paste" likha hai, wo value exactly waise hi daal
do. `<< ... >>` wali cheezein aapko apni taraf se bharni hain.

> App ke pakke facts (ye kahin change mat karna):
> - **App ka naam:** Campster
> - **Package / Application ID:** `com.rexo.marketplace`  *(publish ke baad kabhi change nahi hota)*
> - **Support email:** `rexoagency.in@gmail.com`
> - **Website:** `https://indee289.github.io/Rexo-store-/`
> - **Privacy Policy URL:** `https://indee289.github.io/Rexo-store-/privacy.html`
> - **Account deletion URL:** `https://indee289.github.io/Rexo-store-/docs/account-deletion.html`
> - **Target audience:** 18+ (sirf adults)
> - **Ads:** Nahi (app mein koi advertisement nahi)
> - **In-app purchases:** Nahi (koi coins/subscription/deposit nahi)

---

## 0) Publish karne se pehle (ek baar ka setup)

- [ ] Google Play Developer account bana lo ($25 ek-baar fee). Settings → Developer account verify (identity + address) complete karo — naye accounts ke liye zaroori hai.
- [ ] Signed AAB taiyaar rakho:
  1. GitHub → repo **Actions** → latest **Flutter Build** (green ✓) kholo.
  2. Neeche **Artifacts** se **`Campster-release-aab`** download karo (ye ek ZIP hai).
  3. ZIP ko extract karo → andar **`Campster.aab`** milegi. **Yahi file** upload karni hai (ZIP nahi).
- [ ] 2–8 phone screenshots aur 1 feature graphic (1024×500) taiyaar karo — details §5 mein.

> **Zaroori (naye accounts ke liye):** Agar ye aapka naya personal developer account hai, to Google pehle **Closed testing** maangta hai: kam se kam **12 testers** ko **14 din** tak app test karani padti hai, uske baad hi Production unlock hota hai. Isliye niche hum pehle **Closed testing** se start karenge.

---

## 1) App create karo

**All apps → Create app**

| Field | Kya daalein |
|---|---|
| App name | `Campster` |
| Default language | `English (United States) – en-US` (ya `English (India) – en-IN`) |
| App or game | **App** |
| Free or paid | **Free** |
| Declarations | Dono checkbox tick karo (Developer Program Policies + US export laws) |

**Create app** dabao.

---

## 2) Dashboard → "Set up your app" (saari zaroori declarations)

Left menu → **Policy and programs / App content** (aur Dashboard ke "Set up your app" cards). Ek-ek karke bharo:

### 2.1 App access
- App login maangti hai, isliye Google ke reviewer ko login chahiye.
- Select: **All or some functionality is restricted**
- Ek demo account add karo:
  - Name: `Reviewer login`
  - Username/Email: `<< ek test account email jo app mein bana ho >>`
  - Password: `<< us account ka password >>`
  - Instructions: `Email/password se login karein. Isse creator dashboard, campaigns, messages aur wallet dikhte hain.`
- [ ] Pehle ye demo account app mein sign-up karke bana lo, tabhi reviewer use kar paayega.

### 2.2 Ads
- Select: **No, my app does not contain ads**

### 2.3 Content rating (IARC questionnaire)
- Email: `rexoagency.in@gmail.com`
- Category: **Social / Communication** (ya Reference/Other agar prompt mile)
- Saare sawaalon ka **sach-sach** jawab do:
  - Violence / sexual content / bad language / drugs → **No** (app mein aisa content nahi)
  - User communication / chat / user-generated content share → **Yes** (app mein messaging + profiles hain)
- Submit karo → rating automatically mil jayegi.

### 2.4 Target audience and content
- Target age group: **18 and over** sirf select karo (koi bachon wali age mat choose karna).
- "Appeal to children?" → **No**

### 2.5 Data safety  *(dhyaan se — real data ke hisaab se)*
Niche jaisa declare karo (app actually ye data use karta hai):

**Collected / shared:**
| Data | Collected? | Shared? | Purpose |
|---|---|---|---|
| Name | Yes | No | Account, profile |
| Email address | Yes | No | Account, auth, support |
| User IDs | Yes | No | Account functionality |
| Phone number | Yes (agar user de) | No | Account/verification |
| Photos | Yes (agar user upload kare) | No | Profile / campaign content |
| Messages (in-app chat) | Yes | No | App functionality |
| App activity / interactions | Yes | No | App functionality, analytics |
| Financial info (payout/UPI/bank) | Yes (agar user de) | Payment processing ke liye | Withdrawals/payouts |
| Device IDs / push tokens | Yes | FCM/OneSignal ke saath | Push notifications |
| Location | **No** | — | app location nahi maangta |

**Security declarations:**
- Data is encrypted in transit → **Yes**
- Users can request data deletion → **Yes** (in-app: Settings → Delete Account; web: account deletion URL)
- Account deletion URL: `https://indee289.github.io/Rexo-store-/docs/account-deletion.html`

### 2.6 Government apps
- **No** (ye government app nahi hai)

### 2.7 Financial features
- App creators ko unki earning **withdraw** karne deti hai (payout), lekin **koi lending/banking/crypto/trading nahi** aur users se koi payment/deposit nahi leti.
- Prompt aaye to: koi financial product **nahi** select karo (No lending, No banking, No crypto). Agar "payments/payouts to users" wala option ho to usey honestly mark kar sakte ho.

### 2.8 Privacy Policy
- **App content → Privacy policy** mein paste karo:
  `https://indee289.github.io/Rexo-store-/privacy.html`

### 2.9 Baaki declarations (jaisa prompt mile)
- News app? **No**
- COVID-19 contact tracing? **No**
- Data safety → health/medical? **No**

---

## 3) Store settings (category + contact)

**Grow → Store presence → Store settings** (ya Store listing ke andar):

| Field | Value |
|---|---|
| App category | **Business** (alternative: **Social**) |
| Tags | influencer marketing, creators, marketing |
| Store listing contact – Email | `rexoagency.in@gmail.com` |
| Phone (optional) | `<< optional support phone >>` |
| Website | `https://indee289.github.io/Rexo-store-/` |
| External marketing | koi claim mat karo |

---

## 4) Main store listing (text)

**Grow → Store presence → Main store listing**

- **App name (max 30):** `Campster`
- **Short description (max 80):**
  `Connect creators and brands for influencer marketing campaigns.`
- **Full description (max 4000):** niche wala paste karo (repo ke `store/PLAY_STORE_LISTING.md` se match karta hai):

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
```

---

## 5) Graphics (images)

**Main store listing** ke "Graphics" section mein:

| Asset | Requirement | Source |
|---|---|---|
| App icon | 512×512 PNG, 32-bit, ≤1 MB | launcher icon se banao (`android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` base) |
| Feature graphic | **1024×500** PNG/JPG, no transparency | repo mein ready: `store/assets/feature_graphic.png` (Campster branded) |
| Phone screenshots | 2–8 images, PNG/JPG, portrait recommend **1080×1920** | app chala kar capture karo |

**Screenshots kaise lo (phone par):**
App ke in screens ke screenshot lo (sample/realistic data ke saath):
1. Home / Dashboard
2. Campaigns list
3. Campaign details
4. Jobs list
5. Creator profile
6. Messages / Chat
7. Wallet
8. Settings (privacy/safety)

> Admin/moderation screens mat daalna — wo sirf staff ke liye hain.

---

## 6) Countries aur pricing

- App **Free** hai (pehle hi set).
- **Production → Countries/regions** (ya testing track mein) → jahan launch karna hai wo countries add karo (e.g. India; chahein to aur bhi).

---

## 7) Play App Signing (bahut zaroori)

- Pehli baar AAB upload karte waqt Play **Play App Signing** automatically on karta hai — **accept kar lena**.
- Aap **upload key** se upload karte ho; Google distribute karne ke liye apni **app signing key** use karta hai.
- CI pehle hi correct upload key se sign karti hai aur verify karti hai.
- Baad mein: **Play Console → Setup → App integrity → App signing** mein jo **SHA-256** dikhe, usse repo ke `release-info.txt` ke `signerSha256` se match kar sakte ho.

---

## 8) Release banao aur AAB upload karo

### Step A — pehle Closed testing (recommended / naye account ke liye zaroori)
**Test and release → Testing → Closed testing → Create new release**

1. **Play App Signing** → Continue/accept.
2. **App bundles** → `Campster.aab` upload karo (artifact ZIP se extracted file).
3. **Release name:** `1.0.3 (4)` (ya jo version CI ne banaya — `release-info.txt` mein dikhega).
4. **Release notes:**
   ```
   <en-US>
   First release of Campster — influencer marketing marketplace for creators and brands.
   </en-US>
   ```
5. **Testers:** ek email list bana kar 12+ testers add karo. Unhe opt-in link bhejo.
6. **Save → Review release → Start rollout to Closed testing.**

> Requirement: 12+ testers, 14 din. Isi dauraan upar wale saare App content sections green karte raho.

### Step B — phir Production
Jab closed testing requirement poori ho jaye:
**Test and release → Production → Create new release**
1. Wahi `Campster.aab` (ya nayi build) upload karo.
2. Release notes bharo.
3. **Review release** → koi error/warning na ho → **Start rollout to Production**.

> Tip: pehli baar **Staged rollout** (e.g. 20%) rakh sakte ho, baad mein 100% kar dena.

---

## 9) Final check (rollout se pehle sab green hona chahiye)

- [ ] App access — reviewer demo login diya
- [ ] Ads — No
- [ ] Content rating — complete (IARC)
- [ ] Target audience — 18+
- [ ] Data safety — submitted
- [ ] Privacy policy URL — live aur paste kiya
- [ ] Account deletion URL — live aur paste kiya
- [ ] Store listing — name, short/full description, screenshots, feature graphic, icon
- [ ] Category + contact email
- [ ] Countries selected
- [ ] AAB uploaded (signed, Play App Signing on)
- [ ] Closed testing 12 testers / 14 din (agar naya account)

---

## 10) Reject hone se bachne ke common points

- **Privacy policy / account-deletion URL live honi chahiye** (login ke bina khule, HTTPS). Upload se pehle browser mein kholkar check karo ki dono page aate hain.
- **Reviewer ko kaam karta demo account do** — login ke bina app andar nahi dikhega, warna reject ho sakta hai.
- **Data safety sach mein app ke data use se match kare** — galat declaration par strike aa sakti hai.
- **18+ audience** consistent rakho (privacy policy + app dono 18+ kehte hain).
- **Screenshots asli app ke** hon — fake/AI mockups ya platform logos (Instagram/YouTube) ke claim mat lagao.

---

### Reference files (repo mein)
- `store/PLAY_STORE_LISTING.md` — listing copy + data safety mapping (detailed)
- `PLAY_CONSOLE_CHECKLIST.md` — technical readiness checklist
- `SIGNING.md` — signing / keystore details
- `store/assets/feature_graphic.png` — ready feature graphic

Koi bhi step par screenshot bhejoge to main exactly bata dunga ki us screen par kya choose karna hai.
