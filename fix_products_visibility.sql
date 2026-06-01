-- =====================================================
-- Fix: Make products appear on home screen & catalog
-- =====================================================

-- Step 1: Check current status of all products
SELECT 
  id, 
  name_fr, 
  name_ar, 
  is_active, 
  is_featured, 
  stock_quantity,
  base_price
FROM products
ORDER BY created_at DESC;

-- Step 2: Update all products to be active AND featured
-- (Run this if any products show is_active=false or is_featured=false)
UPDATE products 
SET 
  is_active = true,
  is_featured = true
WHERE id IN (
  SELECT id FROM products
);

-- Step 3: Verify the fix
SELECT 
  id, 
  name_fr, 
  name_ar, 
  is_active, 
  is_featured
FROM products
WHERE is_active = true AND is_featured = true;
