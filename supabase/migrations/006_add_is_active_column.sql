-- ============================================================
-- GROUPE NIKEFA Medical Marketplace
-- Migration: 006 - Add is_active column to products
-- Description: Adds is_active boolean column for soft-deletes
--              and temporary product hiding. Defaults to true
--              for all existing products.
-- Idempotent: Yes (safe to run multiple times)
-- ============================================================

-- Add is_active column if it doesn't exist
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- Ensure existing products are active by default
UPDATE products SET is_active = true WHERE is_active IS NULL;

-- Add index for filtering active products
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active) WHERE is_active = true;

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
