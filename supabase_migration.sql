-- =====================================================
-- GROUPE NIKEFA - COMPLETE FIX FOR SIGNUP ERROR
-- This script fixes ALL common signup issues
-- Run this in Supabase SQL Editor
--
-- ⚠️ DEPRECATED: This is a standalone emergency script.
-- It diverges from the canonical migration chain
-- (migrations/001-009). The migration chain is the
-- source of truth. Use this ONLY as a reference for
-- fixing production signup issues.
-- =====================================================

-- PART 1: Clean up any broken users from failed signups
-- =====================================================
DO $$
DECLARE
  broken_user RECORD;
BEGIN
  FOR broken_user IN 
    SELECT au.id, au.email
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.id IS NULL
  LOOP
    RAISE NOTICE 'Cleaning up broken user: % (%)', broken_user.email, broken_user.id;
    DELETE FROM auth.users WHERE id = broken_user.id;
  END LOOP;
END $$;

-- PART 2: Drop and recreate EVERYTHING from scratch
-- =====================================================

-- Drop the trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop the function
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Drop the table (will recreate)
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop enums (will recreate)
DROP TYPE IF EXISTS public.account_type CASCADE;
DROP TYPE IF EXISTS public.user_role CASCADE;

-- PART 3: Create enums
-- =====================================================
CREATE TYPE public.account_type AS ENUM ('individual', 'hospital', 'laboratory');
CREATE TYPE public.user_role AS ENUM ('customer', 'admin');

-- PART 4: Create profiles table
-- =====================================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  account_type public.account_type NOT NULL DEFAULT 'individual',
  role public.user_role NOT NULL DEFAULT 'customer',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PART 5: Enable RLS and set permissions
-- =====================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON public.profiles TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;

-- PART 6: Create RLS policies
-- =====================================================
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Service role can do everything"
  ON public.profiles
  TO service_role
  USING (true)
  WITH CHECK (true);

-- PART 7: Create updated_at trigger
-- =====================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- PART 8: Create the NEW handle_new_user function (SIMPLIFIED)
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Simple insert with coalesced values
  INSERT INTO public.profiles (id, email, phone, account_type, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    CASE 
      WHEN NEW.raw_user_meta_data->>'account_type' IN ('individual', 'hospital', 'laboratory') 
      THEN (NEW.raw_user_meta_data->>'account_type')::public.account_type
      ELSE 'individual'::public.account_type
    END,
    'customer'::public.user_role
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error with full details
    RAISE WARNING 'handle_new_user failed for %: %', NEW.email, SQLERRM;
    -- Re-raise so we see the error
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- PART 9: Create auth trigger
-- =====================================================
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- PART 10: Verification
-- =====================================================
DO $$
DECLARE
  v_table_exists BOOLEAN;
  v_trigger_exists BOOLEAN;
  v_function_exists BOOLEAN;
BEGIN
  -- Check table
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'profiles'
  ) INTO v_table_exists;
  
  -- Check trigger
  SELECT EXISTS (
    SELECT FROM information_schema.triggers
    WHERE trigger_name = 'on_auth_user_created'
  ) INTO v_trigger_exists;
  
  -- Check function
  SELECT EXISTS (
    SELECT FROM pg_proc 
    WHERE proname = 'handle_new_user'
  ) INTO v_function_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  IF v_table_exists AND v_trigger_exists AND v_function_exists THEN
    RAISE NOTICE 'ALL CHECKS PASSED - Ready for signup!';
  ELSE
    RAISE NOTICE 'SOME CHECKS FAILED:';
    RAISE NOTICE '  Table exists: %', v_table_exists;
    RAISE NOTICE '  Trigger exists: %', v_trigger_exists;
    RAISE NOTICE '  Function exists: %', v_function_exists;
  END IF;
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'IMPORTANT: Also disable email confirmation in:';
  RAISE NOTICE '  Supabase Dashboard -> Authentication -> Settings';
  RAISE NOTICE '  Turn OFF "Confirm email"';
  RAISE NOTICE '';
END $$;
