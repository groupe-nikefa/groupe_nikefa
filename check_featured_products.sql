-- Fix featured products issue
-- Run this in your Supabase SQL Editor

-- 1. Check if any products are marked as featured
SELECT id, name_fr, name_ar, is_featured, created_at 
FROM products 
WHERE is_featured = true 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. If the query above returns 0 rows, mark some products as featured:
-- UPDATE products SET is_featured = true WHERE id IN (
--   SELECT id FROM products ORDER BY created_at DESC LIMIT 8
-- );

-- 3. Check if RLS (Row Level Security) is blocking access
-- This should return true for anon key access:
-- SELECT * FROM products LIMIT 1;

-- 4. If RLS is the issue, ensure the products table has a policy for anon users:
-- CREATE POLICY "Allow anon users to view products" 
-- ON products FOR SELECT 
-- USING (true);
