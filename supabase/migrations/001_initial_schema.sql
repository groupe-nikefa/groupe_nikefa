-- ============================================================
-- GROUPE NIKEFA Medical Marketplace
-- Migration: 001 - Initial Schema
-- Description: Creates all tables, enums, RLS policies,
--              auth triggers, and seed data for MVP v1.
-- Idempotent: Yes (safe to run multiple times)
-- ============================================================

-- ============================================================
-- 1. ENUM TYPES
-- ============================================================

-- Account type for customer segmentation
DO $$ BEGIN
  CREATE TYPE account_type AS ENUM ('individual', 'hospital', 'laboratory');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- User role for authorization (customer vs admin)
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('customer', 'admin');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Order status lifecycle
DO $$ BEGIN
  CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Payment method (MVP: COD only)
DO $$ BEGIN
  CREATE TYPE payment_method AS ENUM ('cod');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- ============================================================
-- 2. TABLES
-- ============================================================

-- -----------------------------------------------------------
-- 2.1 profiles (extends auth.users with app-specific data)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT NOT NULL UNIQUE,
  account_type account_type NOT NULL,
  role user_role NOT NULL DEFAULT 'customer',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------
-- 2.2 categories (supports nested hierarchy via parent_id)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------
-- 2.3 products (medical equipment and consumables)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  name_fr TEXT NOT NULL,
  description_ar TEXT,
  description_fr TEXT,
  base_price NUMERIC(12, 2) NOT NULL CHECK (base_price >= 0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  medical_classification TEXT[],
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  images TEXT[] DEFAULT '{}',
  variants JSONB DEFAULT '[]'::jsonb,
  bulk_pricing JSONB DEFAULT '[]'::jsonb,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------
-- 2.4 orders (customer purchase records)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status order_status NOT NULL DEFAULT 'pending',
  total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
  payment_method payment_method NOT NULL DEFAULT 'cod',
  shipping_address JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------
-- 2.5 order_items (line items within an order)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
  variant_selection JSONB
);

-- -----------------------------------------------------------
-- 2.6 cart_items (synced shopping cart per user)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  variant_selection JSONB,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique constraint on cart items (user + product + variant combination)
CREATE UNIQUE INDEX IF NOT EXISTS idx_cart_items_unique
  ON cart_items (user_id, product_id, COALESCE(variant_selection::text, ''));

-- ============================================================
-- 3. INDEXES (performance optimization)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_cart_items_user ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_featured ON products(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id);

-- ============================================================
-- 4. UPDATED_AT TRIGGER FUNCTION
-- ============================================================

-- Automatically bumps updated_at on any row modification
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all applicable tables
DROP TRIGGER IF EXISTS set_updated_at_profiles ON profiles;
CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_categories ON categories;
CREATE TRIGGER set_updated_at_categories
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_products ON products;
CREATE TRIGGER set_updated_at_products
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_orders ON orders;
CREATE TRIGGER set_updated_at_orders
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_cart_items ON cart_items;
CREATE TRIGGER set_updated_at_cart_items
  BEFORE UPDATE ON cart_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 5. AUTH TRIGGER (auto-create profile on signup)
-- ============================================================

-- Function invoked by Supabase Auth after user creation.
-- Inserts a new profile row with defaults.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';

-- Attach trigger to auth.users (Supabase internal table)
-- Runs AFTER INSERT for each new user row
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on every table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------
-- 6.1 profiles RLS policies
-- -----------------------------------------------------------

-- Users can read their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile (phone, account_type)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins can read all profiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- -----------------------------------------------------------
-- 6.2 categories RLS policies
-- -----------------------------------------------------------

-- Public read access (browsing categories requires no auth)
DROP POLICY IF EXISTS "Public can view categories" ON categories;
CREATE POLICY "Public can view categories"
  ON categories FOR SELECT
  USING (true);

-- Only admins can insert categories
DROP POLICY IF EXISTS "Admins can insert categories" ON categories;
CREATE POLICY "Admins can insert categories"
  ON categories FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can update categories
DROP POLICY IF EXISTS "Admins can update categories" ON categories;
CREATE POLICY "Admins can update categories"
  ON categories FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can delete categories
DROP POLICY IF EXISTS "Admins can delete categories" ON categories;
CREATE POLICY "Admins can delete categories"
  ON categories FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- -----------------------------------------------------------
-- 6.3 products RLS policies
-- -----------------------------------------------------------

-- Public read access (browsing products requires no auth)
-- Only active products are visible to the public
DROP POLICY IF EXISTS "Public can view products" ON products;
CREATE POLICY "Public can view products"
  ON products FOR SELECT
  USING (is_active = true);

-- Only admins can insert products
DROP POLICY IF EXISTS "Admins can insert products" ON products;
CREATE POLICY "Admins can insert products"
  ON products FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can update products
DROP POLICY IF EXISTS "Admins can update products" ON products;
CREATE POLICY "Admins can update products"
  ON products FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can delete products
DROP POLICY IF EXISTS "Admins can delete products" ON products;
CREATE POLICY "Admins can delete products"
  ON products FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- -----------------------------------------------------------
-- 6.4 orders RLS policies
-- -----------------------------------------------------------

-- Users can view their own orders
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (auth.uid() = user_id);

-- Authenticated users can create orders
DROP POLICY IF EXISTS "Users can insert orders" ON orders;
CREATE POLICY "Users can insert orders"
  ON orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all orders
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
CREATE POLICY "Admins can view all orders"
  ON orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update order status
DROP POLICY IF EXISTS "Admins can update orders" ON orders;
CREATE POLICY "Admins can update orders"
  ON orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- -----------------------------------------------------------
-- 6.5 order_items RLS policies
-- -----------------------------------------------------------

-- Users can view their own order items (via parent order)
DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()
    )
  );

-- Users can insert order items for their own orders
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;
CREATE POLICY "Users can insert order items"
  ON order_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()
    )
  );

-- Admins can view all order items
DROP POLICY IF EXISTS "Admins can view all order items" ON order_items;
CREATE POLICY "Admins can view all order items"
  ON order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- -----------------------------------------------------------
-- 6.6 cart_items RLS policies
-- -----------------------------------------------------------

-- Users can view their own cart items
DROP POLICY IF EXISTS "Users can view own cart" ON cart_items;
CREATE POLICY "Users can view own cart"
  ON cart_items FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert into their own cart
DROP POLICY IF EXISTS "Users can insert into own cart" ON cart_items;
CREATE POLICY "Users can insert into own cart"
  ON cart_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own cart items
DROP POLICY IF EXISTS "Users can update own cart" ON cart_items;
CREATE POLICY "Users can update own cart"
  ON cart_items FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own cart items
DROP POLICY IF EXISTS "Users can delete own cart" ON cart_items;
CREATE POLICY "Users can delete own cart"
  ON cart_items FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 7. SEED DATA (sample categories, products, admin placeholder)
-- ============================================================

-- -----------------------------------------------------------
-- 7.1 Sample categories
-- -----------------------------------------------------------
INSERT INTO categories (id, name_ar, name_fr, slug) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'معدات طبية', 'Équipements Médicaux', 'equipements-medicaux'),
  ('a0000000-0000-0000-0000-000000000002', 'مواد استهلاكية', 'Consommables Médicaux', 'consommables-medicaux')
ON CONFLICT (slug) DO NOTHING;

-- -----------------------------------------------------------
-- 7.2 Sample products
-- -----------------------------------------------------------
INSERT INTO products (sku, name_ar, name_fr, description_ar, description_fr, base_price, stock_quantity, category_id, images, is_featured, is_active) VALUES
  (
    'MED-STET-001',
    'سماعة طبية رقمية',
    'Stéthoscope Numérique',
    'سماعة طبية رقمية عالية الدقة مع شاشة LCD لمراقبة معدل ضربات القلب',
    'Stéthoscope numérique haute précision avec écran LCD pour la surveillance du rythme cardiaque',
    125.00,
    50,
    'a0000000-0000-0000-0000-000000000001',
    ARRAY['https://placehold.co/600x600/002664/ffffff?text=Stethoscope'],
    true,
    true
  ),
  (
    'MED-GLOV-002',
    'قفازات طبية معقمة',
    'Gants Médicaux Stériles',
    'قفازات طبية معقمة من النيتريل، خالية من اللاتكس، عبوة 100 قطعة',
    'Gants médicaux stériles en nitrile, sans latex, boîte de 100 unités',
    15.00,
    500,
    'a0000000-0000-0000-0000-000000000002',
    ARRAY['https://placehold.co/600x600/002664/ffffff?text=Gants'],
    true,
    true
  ),
  (
    'MED-SYRN-003',
    'حقن معقمة 5 مل',
    'Seringues Stériles 5ml',
    'حقن معقمة للاستخدام الواحد بسعة 5 مل، عبوة 50 قطعة',
    'Seringues stériles à usage unique de 5 ml, boîte de 50 unités',
    8.50,
    1000,
    'a0000000-0000-0000-0000-000000000002',
    ARRAY['https://placehold.co/600x600/002664/ffffff?text=Seringues'],
    false,
    true
  )
ON CONFLICT (sku) DO NOTHING;

-- -----------------------------------------------------------
-- 7.3 Admin user placeholder
-- NOTE: The actual user must be created via Supabase Auth UI
--       or signUp API. This inserts the profile row only.
--       Replace the UUID below with the real auth.users.id after signup.
-- -----------------------------------------------------------
-- Uncomment and update after creating the admin user via Supabase Auth:
--
-- INSERT INTO profiles (id, phone, account_type, role) VALUES
--   (
--     '00000000-0000-0000-0000-000000000000',  -- Replace with actual auth.users.id
--     '+23566000000',                            -- Chad phone number
--     'individual',
--     'admin'
--   )
-- ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- ============================================================
-- 8. HELPER FUNCTIONS
-- ============================================================

-- Function to check if the current user is an admin
-- Usage: SELECT is_admin();
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  user_role user_role;
BEGIN
  SELECT role INTO user_role
  FROM profiles
  WHERE id = auth.uid();
  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement stock when an order is confirmed
-- This is called by the application after order creation
CREATE OR REPLACE FUNCTION decrement_stock(product_uuid UUID, quantity_int INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE products
  SET stock_quantity = stock_quantity - quantity_int
  WHERE id = product_uuid AND stock_quantity >= quantity_int;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
