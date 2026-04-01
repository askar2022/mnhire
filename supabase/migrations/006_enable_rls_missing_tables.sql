-- Enable Row Level Security on the four tables that have policies defined
-- but RLS was never activated. Without this, policies are ignored and
-- any request with the anon key can read/write all rows.

ALTER TABLE application_answers       ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_stage_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_participants    ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_tasks          ENABLE ROW LEVEL SECURITY;
