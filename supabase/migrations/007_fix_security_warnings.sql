-- Fix all 8 Security Advisor warnings
-- 1. Fix mutable search_path on both functions
-- 2. Replace "always true" RLS INSERT policies with constrained versions

-- ============================================
-- FIX 1: Function Search Path Mutable
-- Prevents a malicious user from hijacking the function via search_path tricks
-- ============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SET search_path = public;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    'Applicant'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public;

-- ============================================
-- FIX 2: applications — "Anyone can insert applications" WITH CHECK (true)
-- Restrict to published jobs only so random rows cannot be inserted
-- ============================================

DROP POLICY IF EXISTS "Anyone can insert applications" ON applications;
CREATE POLICY "Anyone can insert applications" ON applications FOR INSERT
  WITH CHECK (
    job_posting_id IN (
      SELECT id FROM job_postings WHERE posting_status = 'Published'
    )
  );

-- ============================================
-- FIX 3: application_answers — "Anyone can insert answers" WITH CHECK (true)
-- Restrict so answers must belong to a real application
-- ============================================

DROP POLICY IF EXISTS "Anyone can insert answers" ON application_answers;
CREATE POLICY "Anyone can insert answers" ON application_answers FOR INSERT
  WITH CHECK (
    application_id IN (SELECT id FROM applications)
  );

-- ============================================
-- FIX 4: applicants — drop any "always true" INSERT policy
-- Applicant records are created server-side via the API (service_role key),
-- so a public INSERT policy is not needed
-- ============================================

DROP POLICY IF EXISTS "Anyone can insert applicants" ON applicants;
DROP POLICY IF EXISTS "Public can insert applicants" ON applicants;

-- If applicants are submitted without auth, use this constrained version instead:
-- CREATE POLICY "Anyone can insert applicants" ON applicants FOR INSERT
--   WITH CHECK (email IS NOT NULL AND email <> '');

-- ============================================
-- FIX 5: users — drop any "always true" SELECT/INSERT policy
-- User records are created automatically via the handle_new_user trigger,
-- so a public INSERT or SELECT policy with no restriction is not needed
-- ============================================

DROP POLICY IF EXISTS "Public can read all users" ON users;
DROP POLICY IF EXISTS "Anyone can insert users" ON users;
DROP POLICY IF EXISTS "Public can insert users" ON users;
