-- ============================================================================
-- MIGRATION: Add `product_type` to products
--
-- WHY
--   The Shop Admin "Add Product" flow now lets the admin categorise a product
--   as either a physical e-commerce item or a digital item. Physical items
--   track stock / original_price and need full shipping-style detail, digital
--   items need fewer fields. We persist that distinction in a dedicated column
--   so the storefront can render the two kinds differently.
--
-- WHAT
--   Adds a NOT NULL text column `product_type` defaulting to 'ecommerce'
--   (so every existing physical product keeps working), constrained to the two
--   supported values.
--
-- SAFETY
--   - Idempotent: `ADD COLUMN IF NOT EXISTS` + guarded CHECK creation.
--   - Does NOT touch RLS, does NOT drop data, safe to run multiple times.
--
-- >>> NEEDS-USER-ACTION <<<
--   Run this file in the Supabase SQL editor (or via `supabase db`) BEFORE
--   using the new Add Product screen in production. Until it runs, inserts that
--   include `product_type` will fail with "column does not exist".
-- ============================================================================

ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS product_type TEXT NOT NULL DEFAULT 'ecommerce';

-- Add the value check separately so re-running does not error if it exists.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'products_product_type_check'
    ) THEN
        ALTER TABLE public.products
            ADD CONSTRAINT products_product_type_check
            CHECK (product_type IN ('ecommerce', 'digital'));
    END IF;
END$$;

-- ============================================================================
-- VERIFICATION (run after applying):
--   SELECT column_name, data_type, column_default
--   FROM information_schema.columns
--   WHERE table_name = 'products' AND column_name = 'product_type';
--   -- Expect one row: product_type | text | 'ecommerce'::text
-- ============================================================================
