-- ============================================================
-- MNHire Demo Database Setup
-- Run this ONCE in your Supabase SQL Editor
-- Project: crbbzullmkvarpqnkcey.supabase.co
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLES
-- ============================================================

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN (
    'HR', 'Principal', 'HiringManager', 'Interviewer', 'Admin', 'Applicant',
    'AcademicDirector', 'SPEDDirector', 'OperationManager',
    'AssistantPrincipal', 'ITSupport', 'ExecutiveDirector'
  )),
  school_site TEXT CHECK (school_site IN ('Harvest', 'Wakanda', 'Sankofa')),
  is_archived BOOLEAN DEFAULT FALSE,
  archived_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Job postings table
CREATE TABLE IF NOT EXISTS job_postings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  school_site TEXT NOT NULL CHECK (school_site IN ('Harvest', 'Wakanda', 'Sankofa')),
  department TEXT,
  employment_type TEXT CHECK (employment_type IN ('Full-time', 'Part-time', 'Contract')),
  location TEXT,
  description TEXT,
  requirements TEXT,
  salary_range_min DECIMAL(10, 2),
  salary_range_max DECIMAL(10, 2),
  posting_status TEXT NOT NULL DEFAULT 'Draft' CHECK (posting_status IN ('Draft', 'Published', 'Closed')),
  created_by UUID REFERENCES users(id),
  hiring_manager_id UUID REFERENCES users(id),
  pipeline_template_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

-- Applicants table
CREATE TABLE IF NOT EXISTS applicants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  linked_in TEXT,
  website TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Applications table
CREATE TABLE IF NOT EXISTS applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_posting_id UUID NOT NULL REFERENCES job_postings(id) ON DELETE CASCADE,
  applicant_id UUID NOT NULL REFERENCES applicants(id) ON DELETE CASCADE,
  source TEXT,
  status TEXT NOT NULL DEFAULT 'Draft' CHECK (status IN (
    'Draft', 'Submitted', 'Under Review', 'Phone Screen',
    'Interview', 'Reference Check', 'Offered', 'Hired', 'Rejected', 'Withdrawn'
  )),
  resume_url TEXT,
  cover_letter_url TEXT,
  additional_docs JSONB,
  years_experience INTEGER,
  certifications TEXT,
  notes_internal TEXT,
  submitted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(job_posting_id, applicant_id)
);

-- Application answers table
CREATE TABLE IF NOT EXISTS application_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Application stage history
CREATE TABLE IF NOT EXISTS application_stage_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID REFERENCES users(id),
  comment TEXT,
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Interviews table
CREATE TABLE IF NOT EXISTS interviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  stage TEXT NOT NULL CHECK (stage IN ('Phone Screen', 'Panel Interview', 'Demo Lesson', 'Final Interview')),
  scheduled_at TIMESTAMPTZ NOT NULL,
  location TEXT,
  created_by UUID REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')),
  join_link TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Interview feedback table
CREATE TABLE IF NOT EXISTS interview_feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  interview_id UUID NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES users(id),
  rating_overall INTEGER CHECK (rating_overall >= 1 AND rating_overall <= 5),
  ratings_json JSONB,
  comments TEXT,
  recommendation TEXT CHECK (recommendation IN ('Strong Hire', 'Hire', 'Maybe', 'No Hire')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(interview_id, reviewer_id)
);

-- Interview participants
CREATE TABLE IF NOT EXISTS interview_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  interview_id UUID NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'Interviewer',
  UNIQUE(interview_id, user_id)
);

-- Offers table
CREATE TABLE IF NOT EXISTS offers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft', 'Sent', 'Accepted', 'Declined')),
  salary DECIMAL(10, 2),
  start_date DATE,
  offer_letter_url TEXT,
  sent_at TIMESTAMPTZ,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hires table
CREATE TABLE IF NOT EXISTS hires (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  employee_internal_id TEXT,
  school_site TEXT NOT NULL CHECK (school_site IN ('Harvest', 'Wakanda', 'Sankofa')),
  position_title TEXT NOT NULL,
  start_date DATE,
  onboarding_status TEXT DEFAULT 'Not Started' CHECK (onboarding_status IN ('Not Started', 'In Progress', 'Completed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Onboarding tasks table
CREATE TABLE IF NOT EXISTS onboarding_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  hire_id UUID NOT NULL REFERENCES hires(id) ON DELETE CASCADE,
  task_name TEXT NOT NULL,
  task_type TEXT CHECK (task_type IN ('Background Check', 'I-9', 'W-4', 'Fingerprinting', 'Licensure Verification', 'Orientation', 'System Accounts')),
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed')),
  assigned_to UUID REFERENCES users(id),
  due_date DATE,
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_applications_job_posting ON applications(job_posting_id);
CREATE INDEX IF NOT EXISTS idx_applications_applicant ON applications(applicant_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_job_postings_status ON job_postings(posting_status);
CREATE INDEX IF NOT EXISTS idx_job_postings_school ON job_postings(school_site);
CREATE INDEX IF NOT EXISTS idx_interviews_application ON interviews(application_id);
CREATE INDEX IF NOT EXISTS idx_interview_feedback_interview ON interview_feedback(interview_id);
CREATE INDEX IF NOT EXISTS idx_offers_application ON offers(application_id);
CREATE INDEX IF NOT EXISTS idx_hires_application ON hires(application_id);

-- ============================================================
-- TRIGGER FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SET search_path = public;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_job_postings_updated_at ON job_postings;
DROP TRIGGER IF EXISTS update_applications_updated_at ON applications;
DROP TRIGGER IF EXISTS update_interviews_updated_at ON interviews;
DROP TRIGGER IF EXISTS update_interview_feedback_updated_at ON interview_feedback;
DROP TRIGGER IF EXISTS update_offers_updated_at ON offers;
DROP TRIGGER IF EXISTS update_hires_updated_at ON hires;
DROP TRIGGER IF EXISTS update_onboarding_tasks_updated_at ON onboarding_tasks;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_job_postings_updated_at BEFORE UPDATE ON job_postings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_interviews_updated_at BEFORE UPDATE ON interviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_interview_feedback_updated_at BEFORE UPDATE ON interview_feedback FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON offers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_hires_updated_at BEFORE UPDATE ON hires FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_onboarding_tasks_updated_at BEFORE UPDATE ON onboarding_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create user profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_postings ENABLE ROW LEVEL SECURITY;
ALTER TABLE applicants ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_stage_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE interviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE hires ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_tasks ENABLE ROW LEVEL SECURITY;

-- USERS
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can insert own record" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "HR can read all users" ON users;
DROP POLICY IF EXISTS "HR can update any user" ON users;

CREATE POLICY "Users can read own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own record" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "HR can read all users" ON users FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can update any user" ON users FOR UPDATE
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));

-- JOB POSTINGS
DROP POLICY IF EXISTS "Public can read published jobs" ON job_postings;
DROP POLICY IF EXISTS "HR can manage all jobs" ON job_postings;
DROP POLICY IF EXISTS "Hiring managers can read own jobs" ON job_postings;

CREATE POLICY "Public can read published jobs" ON job_postings FOR SELECT USING (posting_status = 'Published');
CREATE POLICY "HR can manage all jobs" ON job_postings FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "Hiring managers can read own jobs" ON job_postings FOR SELECT
  USING (hiring_manager_id = auth.uid() OR EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));

-- APPLICANTS
DROP POLICY IF EXISTS "Applicants can read own data" ON applicants;
DROP POLICY IF EXISTS "HR can read all applicants" ON applicants;
DROP POLICY IF EXISTS "HR can insert applicants" ON applicants;
DROP POLICY IF EXISTS "HR can update applicants" ON applicants;

CREATE POLICY "Applicants can read own data" ON applicants FOR SELECT
  USING (email = (SELECT email FROM users WHERE id = auth.uid()));
CREATE POLICY "HR can read all applicants" ON applicants FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can insert applicants" ON applicants FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can update applicants" ON applicants FOR UPDATE
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));

-- APPLICATIONS
DROP POLICY IF EXISTS "Applicants can read own applications" ON applications;
DROP POLICY IF EXISTS "HR can read all applications" ON applications;
DROP POLICY IF EXISTS "HR can manage all applications" ON applications;
DROP POLICY IF EXISTS "Anyone can insert applications" ON applications;
DROP POLICY IF EXISTS "Hiring managers can update their applications" ON applications;

CREATE POLICY "Applicants can read own applications" ON applications FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM applicants WHERE applicants.id = applications.applicant_id
    AND applicants.email = (SELECT email FROM users WHERE id = auth.uid())
  ));
CREATE POLICY "HR can read all applications" ON applications FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can manage all applications" ON applications FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "Anyone can insert applications" ON applications FOR INSERT
  WITH CHECK (job_posting_id IN (SELECT id FROM job_postings WHERE posting_status = 'Published'));
CREATE POLICY "Hiring managers can update their applications" ON applications FOR UPDATE
  USING (EXISTS (SELECT 1 FROM job_postings jp WHERE jp.id = applications.job_posting_id AND jp.hiring_manager_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM job_postings jp WHERE jp.id = applications.job_posting_id AND jp.hiring_manager_id = auth.uid()));

-- APPLICATION ANSWERS
DROP POLICY IF EXISTS "Applicants can read own answers" ON application_answers;
DROP POLICY IF EXISTS "HR can read all answers" ON application_answers;
DROP POLICY IF EXISTS "Anyone can insert answers" ON application_answers;
DROP POLICY IF EXISTS "HR can update answers" ON application_answers;
DROP POLICY IF EXISTS "HR can delete answers" ON application_answers;

CREATE POLICY "Applicants can read own answers" ON application_answers FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM applications a JOIN applicants ap ON ap.id = a.applicant_id
    WHERE a.id = application_answers.application_id
    AND ap.email = (SELECT email FROM users WHERE id = auth.uid())
  ));
CREATE POLICY "HR can read all answers" ON application_answers FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "Anyone can insert answers" ON application_answers FOR INSERT
  WITH CHECK (application_id IN (SELECT id FROM applications));
CREATE POLICY "HR can update answers" ON application_answers FOR UPDATE
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can delete answers" ON application_answers FOR DELETE
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));

-- APPLICATION STAGE HISTORY
DROP POLICY IF EXISTS "Applicants can read own history" ON application_stage_history;
DROP POLICY IF EXISTS "HR can read all history" ON application_stage_history;
DROP POLICY IF EXISTS "HR can insert history" ON application_stage_history;
DROP POLICY IF EXISTS "HR can update history" ON application_stage_history;
DROP POLICY IF EXISTS "HR can delete history" ON application_stage_history;

CREATE POLICY "Applicants can read own history" ON application_stage_history FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM applications a JOIN applicants ap ON ap.id = a.applicant_id
    WHERE a.id = application_stage_history.application_id
    AND ap.email = (SELECT email FROM users WHERE id = auth.uid())
  ));
CREATE POLICY "HR can read all history" ON application_stage_history FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "HR can insert history" ON application_stage_history FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "HR can update history" ON application_stage_history FOR UPDATE
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can delete history" ON application_stage_history FOR DELETE
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));

-- INTERVIEWS
DROP POLICY IF EXISTS "Applicants can read own interviews" ON interviews;
DROP POLICY IF EXISTS "HR can read all interviews" ON interviews;
DROP POLICY IF EXISTS "Interviewers can read assigned interviews" ON interviews;
DROP POLICY IF EXISTS "HR can manage interviews" ON interviews;

CREATE POLICY "Applicants can read own interviews" ON interviews FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM applications a JOIN applicants ap ON ap.id = a.applicant_id
    WHERE a.id = interviews.application_id
    AND ap.email = (SELECT email FROM users WHERE id = auth.uid())
  ));
CREATE POLICY "HR can read all interviews" ON interviews FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "Interviewers can read assigned interviews" ON interviews FOR SELECT
  USING (EXISTS (SELECT 1 FROM interview_participants ip WHERE ip.interview_id = interviews.id AND ip.user_id = auth.uid()));
CREATE POLICY "HR can manage interviews" ON interviews FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));

-- INTERVIEW PARTICIPANTS
DROP POLICY IF EXISTS "Participants can read own assignments" ON interview_participants;
DROP POLICY IF EXISTS "HR can read all participants" ON interview_participants;
DROP POLICY IF EXISTS "HR can manage participants" ON interview_participants;
DROP POLICY IF EXISTS "Participants can update own assignments" ON interview_participants;

CREATE POLICY "Participants can read own assignments" ON interview_participants FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "HR can read all participants" ON interview_participants FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "HR can manage participants" ON interview_participants FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "Participants can update own assignments" ON interview_participants FOR UPDATE
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- INTERVIEW FEEDBACK
DROP POLICY IF EXISTS "Reviewers can read own feedback" ON interview_feedback;
DROP POLICY IF EXISTS "HR can read all feedback" ON interview_feedback;
DROP POLICY IF EXISTS "Interviewers can manage own feedback" ON interview_feedback;

CREATE POLICY "Reviewers can read own feedback" ON interview_feedback FOR SELECT USING (reviewer_id = auth.uid());
CREATE POLICY "HR can read all feedback" ON interview_feedback FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "Interviewers can manage own feedback" ON interview_feedback FOR ALL
  USING (reviewer_id = auth.uid()) WITH CHECK (reviewer_id = auth.uid());

-- OFFERS
DROP POLICY IF EXISTS "Applicants can read own offers" ON offers;
DROP POLICY IF EXISTS "HR can read all offers" ON offers;
DROP POLICY IF EXISTS "HR can manage offers" ON offers;

CREATE POLICY "Applicants can read own offers" ON offers FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM applications a JOIN applicants ap ON ap.id = a.applicant_id
    WHERE a.id = offers.application_id
    AND ap.email = (SELECT email FROM users WHERE id = auth.uid())
  ));
CREATE POLICY "HR can read all offers" ON offers FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin', 'Principal', 'HiringManager')));
CREATE POLICY "HR can manage offers" ON offers FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));

-- HIRES
DROP POLICY IF EXISTS "HR can read all hires" ON hires;
DROP POLICY IF EXISTS "HR can manage hires" ON hires;

CREATE POLICY "HR can read all hires" ON hires FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can manage hires" ON hires FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));

-- ONBOARDING TASKS
DROP POLICY IF EXISTS "HR can read all onboarding tasks" ON onboarding_tasks;
DROP POLICY IF EXISTS "HR can manage onboarding tasks" ON onboarding_tasks;
DROP POLICY IF EXISTS "Users can read assigned tasks" ON onboarding_tasks;
DROP POLICY IF EXISTS "Users can update assigned tasks" ON onboarding_tasks;

CREATE POLICY "HR can read all onboarding tasks" ON onboarding_tasks FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "HR can manage onboarding tasks" ON onboarding_tasks FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('HR', 'Admin')));
CREATE POLICY "Users can read assigned tasks" ON onboarding_tasks FOR SELECT USING (assigned_to = auth.uid());
CREATE POLICY "Users can update assigned tasks" ON onboarding_tasks FOR UPDATE
  USING (assigned_to = auth.uid()) WITH CHECK (assigned_to = auth.uid());

-- ============================================================
-- STORAGE BUCKET
-- Run in Supabase Dashboard > Storage > Create Bucket:
--   Name: applications
--   Public: true (so resume URLs work)
-- Then run these policies:
-- ============================================================

-- Storage policies (run after creating the 'applications' bucket)
-- INSERT: allow authenticated users to upload
INSERT INTO storage.buckets (id, name, public) VALUES ('applications', 'applications', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Authenticated users can upload files" ON storage.objects FOR INSERT
  TO authenticated WITH CHECK (bucket_id = 'applications');

CREATE POLICY "Public can view files" ON storage.objects FOR SELECT
  TO public USING (bucket_id = 'applications');

CREATE POLICY "Users can delete own files" ON storage.objects FOR DELETE
  TO authenticated USING (bucket_id = 'applications' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- DONE! Now:
-- 1. Copy the anon key + service_role key from Supabase Dashboard > Settings > API
-- 2. Paste them into C:\mnhire-app\.env.local
-- 3. Enable Google OAuth in Supabase Dashboard > Authentication > Providers
-- 4. Set Site URL to https://demo.mnhire.org in Auth > URL Configuration
-- ============================================================
