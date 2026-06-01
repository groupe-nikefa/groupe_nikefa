-- =====================================================
-- GROUPE NIKEFA - Database Setup Verification Script
-- Run this AFTER running supabase_migration.sql
-- =====================================================

-- Check 1: Verify enums exist
-- =====================================================
SELECT '✓ account_type enum exists' as status
FROM pg_type 
WHERE typname = 'account_type'
UNION ALL
SELECT '✗ account_type enum MISSING'
WHERE NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_type');

SELECT '✓ user_role enum exists' as status
FROM pg_type 
WHERE typname = 'user_role'
UNION ALL
SELECT '✗ user_role enum MISSING'
WHERE NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role');

-- Check 2: Verify profiles table exists
-- =====================================================
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'profiles'
    ) THEN '✓ profiles table exists'
    ELSE '✗ profiles table MISSING'
  END as status;

-- Check 3: Verify table structure
-- =====================================================
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Check 4: Verify triggers exist
-- =====================================================
SELECT 
  trigger_name,
  event_manipulation,
  event_object_schema || '.' || event_object_table as table_name,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema IN ('public', 'auth')
  AND trigger_name IN ('on_auth_user_created', 'set_profiles_updated_at');

-- Check 5: Verify RLS policies
-- =====================================================
SELECT 
  polname as policy_name,
  polcmd as command,
  polroles::regrole[] as roles
FROM pg_policy 
WHERE polrelid = 'public.profiles'::regclass;

-- Check 6: Verify RLS is enabled
-- =====================================================
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'profiles';

-- Check 7: Test profile creation manually
-- =====================================================
-- This simulates what the trigger does
-- Run this ONLY if you want to test manually (optional)
/*
INSERT INTO public.profiles (id, phone, account_type)
VALUES (
  gen_random_uuid(),
  '0123456789',
  'individual'::account_type
);

-- Check if it was inserted
SELECT p.*, u.email
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
WHERE u.email = 'test@test.com';

-- Clean up
DELETE FROM public.profiles WHERE id IN (
  SELECT id FROM auth.users WHERE email = 'test@test.com'
);
*/

-- Check 8: View recent profiles (last 10)
-- =====================================================
SELECT 
  p.id,
  u.email,
  p.phone,
  p.account_type,
  p.role,
  p.created_at
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
ORDER BY p.created_at DESC
LIMIT 10;

-- Check 9: Count total profiles
-- =====================================================
SELECT 
  COUNT(*) as total_profiles,
  COUNT(*) FILTER (WHERE account_type = 'individual') as individuals,
  COUNT(*) FILTER (WHERE account_type = 'hospital') as hospitals,
  COUNT(*) FILTER (WHERE account_type = 'laboratory') as laboratories
FROM public.profiles;

-- =====================================================
-- SUCCESS! All checks completed
-- =====================================================
