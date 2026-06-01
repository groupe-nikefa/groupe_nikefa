-- Migration: 002_fix_category_fk_constraint.sql
-- Purpose: Fix contradictory FK constraint on products.category_id
--          (was NOT NULL with ON DELETE SET NULL, now ON DELETE RESTRICT NOT NULL)

-- Step 1: Pre-check — halt if any products have NULL category_id
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM products WHERE category_id IS NULL) THEN
    RAISE EXCEPTION 'Migration aborted: Found products with NULL category_id. Please assign a valid category to all products before running this migration.';
  END IF;
END $$;

-- Step 2: Drop the existing broken FK constraint if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_type = 'FOREIGN KEY'
      AND constraint_name = 'products_category_id_fkey'
      AND table_name = 'products'
      AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.products DROP CONSTRAINT products_category_id_fkey;
  END IF;
END $$;

-- Step 3: Recreate the FK constraint with ON DELETE RESTRICT NOT NULL
ALTER TABLE public.products
  ALTER COLUMN category_id SET NOT NULL,
  ADD CONSTRAINT products_category_id_fkey
    FOREIGN KEY (category_id)
    REFERENCES public.categories(id)
    ON DELETE RESTRICT;

-- Step 4: Create index on products(category_id) if it does not already exist
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
