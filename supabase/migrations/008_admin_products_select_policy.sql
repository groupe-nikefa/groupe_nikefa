-- ============================================================
-- GROUPE NIKEFA Medical Marketplace
-- Migration: 008 - Add admin products SELECT policy & Realtime
-- Description: 
--   1. Adds admin-specific SELECT RLS policy on products so
--      admins can see all products (including inactive ones)
--      in the admin dashboard. Previously only the public
--      policy existed, limiting visibility to is_active = true.
--   2. Ensures the products table is in the Realtime publication
--      so the admin stream subscription emits data.
-- Idempotent: Yes (safe to run multiple times)
-- ============================================================

-- -----------------------------------------------------------
-- 1. Admin SELECT policy on products
--    Admins bypass the is_active = true filter to see all
--    products in the admin dashboard.
--    Since RLS policies are OR'd together, this coexists with
--    the existing public policy.
-- -----------------------------------------------------------
DROP POLICY IF EXISTS "Admins can view all products" ON products;
CREATE POLICY "Admins can view all products"
  ON products FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- -----------------------------------------------------------
-- 2. Add products table to Realtime publication
--    The admin product screen uses supabase_flutter's .stream()
--    which requires Realtime to be enabled. Without this, the
--    stream subscription never emits data.
-- -----------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'products'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE products;
  END IF;
END $$;

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
