-- ============================================================
-- GROUPE NIKEFA Medical Marketplace
-- Migration: 009 - Fix Schema Security & Missing Policies
-- Description:
--   - Fix SECURITY DEFINER search_path on handle_new_user
--   - Fix is_admin() to return false instead of NULL
--   - Add DELETE policies for orders and order_items
--   - Drop duplicate index on products(category_id)
--   - Add partial index on profiles(role) for admin queries
-- ============================================================

-- Fix C9: Add SET search_path to handle_new_user to prevent
-- search_path injection attacks
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, account_type, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(
      (NEW.raw_user_meta_data->>'account_type')::account_type,
      'individual'
    ),
    'customer'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fix H4: Make is_admin() return false instead of NULL
-- when auth.uid() is NULL (unauthenticated calls)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  user_role user_role;
BEGIN
  SELECT role INTO user_role
  FROM profiles
  WHERE id = auth.uid();
  RETURN COALESCE(user_role = 'admin', false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = 'public';

-- Fix C10: Add DELETE policies for orders (admins only)
DROP POLICY IF EXISTS "Admins can delete orders" ON orders;
CREATE POLICY "Admins can delete orders"
  ON orders FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Fix C10: Add DELETE policies for order_items (admins only)
DROP POLICY IF EXISTS "Admins can delete order items" ON order_items;
CREATE POLICY "Admins can delete order items"
  ON order_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Fix H2: Drop duplicate index on products(category_id)
-- idx_products_category (001) is the canonical one
DROP INDEX IF EXISTS idx_products_category_id;

-- Fix H4 (perf): Add partial index for admin role checks
CREATE INDEX IF NOT EXISTS idx_profiles_admin
  ON profiles(role)
  WHERE role = 'admin';
