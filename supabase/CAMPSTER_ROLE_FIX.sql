-- ============================================================================
-- Campster — ROLE FIX (brand vs creator)
--
-- Problem: har user 'creator' ban jaata tha chahe signup par 'brand' chuna ho.
-- Wajah: ek BEFORE-UPDATE trigger (prevent_user_self_escalation) non-admin ke
-- har role change ko revert kar deta tha (NEW.role := OLD.role).
--
-- Ye script trigger ko relax karti hai: non-admin ab 'creator' aur 'brand' ke
-- beech switch kar sakta hai, par 'admin' nahi ban sakta; isVerified/isBanned
-- abhi bhi protected hain. Saath hi existing roles ko lowercase normalize
-- karti hai (CHECK constraint 'creator','brand','admin' ke liye).
--
-- Supabase Dashboard → SQL Editor mein poori file ek baar run kar do.
-- ============================================================================

-- 1) Existing roles lowercase (purane 'CREATOR'/'Brand' ko normalize karo).
UPDATE public.users
SET role = lower(role)
WHERE role IS NOT NULL AND role <> lower(role);

-- 2) Trigger function ko relax karo.
CREATE OR REPLACE FUNCTION public.prevent_user_self_escalation()
RETURNS TRIGGER AS $$
BEGIN
  -- Admins par koi restriction nahi.
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  -- Non-admin: sirf 'creator' <-> 'brand' allowed. 'admin' ban-na ya admin se
  -- hat-na block. Baaki case mein purana role wapas.
  IF lower(coalesce(NEW.role, '')) IN ('creator', 'brand')
     AND lower(coalesce(OLD.role, '')) <> 'admin' THEN
    NEW.role := lower(NEW.role);
  ELSE
    NEW.role := OLD.role;
  END IF;

  -- Ye fields sirf admin change kar sakta hai.
  NEW."isVerified" := OLD."isVerified";
  NEW."isBanned"   := OLD."isBanned";
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3) (Optional) Kisi specific user ko manually brand banana ho to uncomment:
-- UPDATE public.users SET role = 'brand' WHERE email = 'user@example.com';

-- 4) Verify:
-- SELECT email, role FROM public.users ORDER BY "createdAt" DESC LIMIT 20;
