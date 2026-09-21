# PGRST205 Fix — Step by Step (Hinglish)

App mein Jobs/Banners pe **"Could not find the table 'public.jobs' in the schema cache"** aa raha hai.

**Ye kya hai:** Tables, permissions, RLS, data — sab bilkul theek hain (humne check kiya). Problem sirf itni hai ki Supabase ka **API layer (PostgREST) ka cache purana hai** — usko naye tables abhi tak dikhte nahi. Bas cache refresh karna hai.

Neeche 3 method hain. **Order mein karo** — pehla na chale to doosra, phir teesra. Teeno mein se koi ek pakka kaam karega.

---

## ✅ METHOD 1 — SQL se force reload (pehle ye)

1. Supabase Dashboard → **SQL Editor**
2. File `supabase/FORCE_SCHEMA_RELOAD.sql` ka **poora content** copy karke paste karo
3. **Run** dabao
4. **1-2 minute wait** karo
5. App kholo → Jobs → **Retry**

Chal gaya? ✅ Ho gaya. Nahi chala? → Method 2.

---

## ✅ METHOD 2 — Exposed Schemas toggle (ye HAMESHA kaam karta hai)

1. Supabase Dashboard → **Settings** (⚙️) → **API**
2. **"Exposed schemas"** dhoondo (usme `public` likha hoga)
3. `public` ko **REMOVE** karo → **Save** → **30 second wait**
4. `public` ko **wapas ADD** karo → **Save** → **60 second wait**
5. App kholo → Jobs → **Retry**

Ye PostgREST ko poori tarah config + schema reload karne pe majboor karta hai. Chal gaya? ✅ Nahi? → Method 3.

---

## ✅ METHOD 3 — Project Restart (aakhri lever)

1. Supabase Dashboard → **Settings** (⚙️) → **General**
2. **"Restart project"** → confirm
3. **POORE 5 minute wait** karo (status "Healthy" hone tak)
4. App kholo → Jobs → **Retry**

---

## Success kaisा dikhega:

- Jobs page pe **tumhara test job** (₹500 wala "Test Job - Instagram Reel") dikhega
- Manage Jobs / Review Submissions / Banners bhi khulenge
- "Something went wrong" / "not found" nahi aayega
- Agar koi job/banner nahi hai to **"No jobs" empty state** dikhega (error nahi)

---

## Note:
- Free tier pe API cache kabhi-kabhi **2-3 min lag** sakta hai update hone mein — wait zaroor karo.
- Ye ek baar theek hone ke baad dobara nahi hoga (default privileges set kar diye hain future tables ke liye).
