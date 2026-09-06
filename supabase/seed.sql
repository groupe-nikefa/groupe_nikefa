-- ============================================================
-- GROUPE NIKEFA — Seed Data Script
-- Run this AFTER applying migration 001_initial_schema.sql
-- Idempotent: safe to run multiple times
-- ============================================================

-- -----------------------------------------------------------
-- 1. Promote first admin user
--    Finds the user by email and sets role = 'admin'
--    Replace 'admin@nikefa.com' with the actual admin email
-- -----------------------------------------------------------
DO $$
DECLARE
  admin_uid UUID;
BEGIN
  SELECT id INTO admin_uid FROM auth.users WHERE email = 'sudangptmail@gmail.com';
  IF admin_uid IS NOT NULL THEN
    UPDATE profiles
    SET role = 'admin'
    WHERE id = admin_uid AND role != 'admin';
    RAISE NOTICE 'Admin role set for user: sudangptmail@gmail.com (%)', admin_uid;
  ELSE
    RAISE NOTICE 'Admin user sudangptmail@gmail.com not found in auth.users';
  END IF;
END $$;

-- -----------------------------------------------------------
-- 2. Sample categories (skip if already exist)
-- -----------------------------------------------------------
INSERT INTO categories (id, name_ar, name_fr, slug) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'معدات طبية', 'Équipements Médicaux', 'equipements-medicaux'),
  ('a0000000-0000-0000-0000-000000000002', 'مواد استهلاكية', 'Consommables Médicaux', 'consommables-medicaux'),
  ('a0000000-0000-0000-0000-000000000003', 'أدوات المختبر', 'Instruments de Laboratoire', 'instruments-laboratoire'),
  ('a0000000-0000-0000-0000-000000000004', 'معدات الوقاية', 'Équipements de Protection', 'equipements-protection')
ON CONFLICT (slug) DO NOTHING;

-- -----------------------------------------------------------
-- 3. Sample products (skip if sku already exists)
--    Using Unsplash CDN images for an attractive sales demo
-- -----------------------------------------------------------
INSERT INTO products (sku, name_ar, name_fr, description_ar, description_fr, base_price, stock_quantity, category_id, images, is_featured) VALUES
  (
    'MED-STET-001',
    'سماعة طبية رقمية',
    'Stéthoscope Numérique',
    'سماعة طبية رقمية عالية الدقة مع شاشة LCD لمراقبة معدل ضربات القلب',
    'Stéthoscope numérique haute précision avec écran LCD pour la surveillance du rythme cardiaque',
    125.00, 50,
    'a0000000-0000-0000-0000-000000000001',
    ARRAY['https://images.unsplash.com/photo-1584982751601-97dcc096659c?auto=format&fit=crop&w=600&q=60'],
    true
  ),
  (
    'MED-GLOV-002',
    'قفازات طبية معقمة',
    'Gants Médicaux Stériles',
    'قفازات طبية معقمة من النيتريل، خالية من اللاتكس، عبوة 100 قطعة',
    'Gants médicaux stériles en nitrile, sans latex, boîte de 100 unités',
    15.00, 500,
    'a0000000-0000-0000-0000-000000000002',
    ARRAY['https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&w=600&q=60'],
    true
  ),
  (
    'MED-SYRN-003',
    'حقن معقمة 5 مل',
    'Seringues Stériles 5ml',
    'حقن معقمة للاستخدام الواحد بسعة 5 مل، عبوة 50 قطعة',
    'Seringues stériles à usage unique de 5 ml, boîte de 50 unités',
    8.50, 1000,
    'a0000000-0000-0000-0000-000000000002',
    ARRAY['https://images.unsplash.com/photo-1632685061325-3f0f2c6a4a1e?auto=format&fit=crop&w=600&q=60'],
    false
  ),
  (
    'LAB-MICR-004',
    'مجهر إلكتروني',
    'Microscope Électronique',
    'مجهر إلكتروني عالي التكبير للاستخدام المخبري مع إضاءة LED',
    'Microscope électronique à fort grossissement pour usage en laboratoire avec éclairage LED',
    450.00, 15,
    'a0000000-0000-0000-0000-000000000003',
    ARRAY['https://images.unsplash.com/photo-1579154204601-01588f351e67?auto=format&fit=crop&w=600&q=60'],
    false
  ),
  (
    'PROT-MASK-005',
    'كمامات طبية N95',
    'Masques Médicaux N95',
    'كمامات طبية N95 عالية الجودة، عبوة 50 قطعة',
    'Masques médicaux N95 de haute qualité, boîte de 50 unités',
    25.00, 300,
    'a0000000-0000-0000-0000-000000000004',
    ARRAY['https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=60'],
    true
  )
ON CONFLICT (sku) DO NOTHING;
