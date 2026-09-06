-- ============================================================
-- GROUPE NIKEFA — Migration 010: Replace dead placeholder images
-- Replaces via.placeholder.com / placehold.co URLs (which no longer
-- load) with Unsplash CDN images so the storefront looks attractive.
-- Idempotent: only touches rows whose images still contain
-- 'placeholder'. Safe to run multiple times.
-- HOW TO APPLY: Supabase Dashboard → SQL Editor → paste & Run.
-- ============================================================

-- 1. Known seed products (matched by SKU for a fitting image each).
UPDATE products
SET images = ARRAY['https://images.unsplash.com/photo-1584982751601-97dcc096659c?auto=format&fit=crop&w=600&q=60'],
    updated_at = NOW()
WHERE sku = 'MED-STET-001'
  AND images::text LIKE '%placeholder%';

UPDATE products
SET images = ARRAY['https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&w=600&q=60'],
    updated_at = NOW()
WHERE sku = 'MED-GLOV-002'
  AND images::text LIKE '%placeholder%';

UPDATE products
SET images = ARRAY['https://images.unsplash.com/photo-1632685061325-3f0f2c6a4a1e?auto=format&fit=crop&w=600&q=60'],
    updated_at = NOW()
WHERE sku = 'MED-SYRN-003'
  AND images::text LIKE '%placeholder%';

UPDATE products
SET images = ARRAY['https://images.unsplash.com/photo-1579154204601-01588f351e67?auto=format&fit=crop&w=600&q=60'],
    updated_at = NOW()
WHERE sku = 'LAB-MICR-004'
  AND images::text LIKE '%placeholder%';

UPDATE products
SET images = ARRAY['https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=60'],
    updated_at = NOW()
WHERE sku = 'PROT-MASK-005'
  AND images::text LIKE '%placeholder%';

-- 2. Fallback: any other product still pointing at a placeholder
-- service gets a neutral medical image instead of a broken icon.
UPDATE products
SET images = ARRAY['https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=600&q=60'],
    updated_at = NOW()
WHERE images::text LIKE '%placeholder%';
