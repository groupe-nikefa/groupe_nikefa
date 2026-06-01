-- ============================================================
-- GROUPE NIKEFA Medical Marketplace
-- Migration: 007 - Fix infinite recursion in profiles RLS
-- Description: Replaces the admin policy on profiles that
--              directly queried the profiles table (causing
--              infinite recursion) with one using is_admin().
-- ============================================================

-- Fix: Use is_admin() SECURITY DEFINER function instead of
-- directly querying profiles within its own RLS policy.
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING (is_admin());
