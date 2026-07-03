/*
  # FinTrack India - Complete Database Schema

  ## Overview
  AI-powered personal finance tracker for Indian users with INR support.

  ## Tables Created
  1. `profiles` — Extended user profile data linked to auth.users
  2. `transactions` — Income and expense records in INR
  3. `budgets` — Monthly category-based budget limits with alert tracking
  4. `receipt_scans` — AI-processed receipt records
  5. `notifications` — Budget alert and system notification log
  6. `stock_recommendations` — AI-generated stock suggestions

  ## Security
  - RLS enabled on all tables
  - All policies restrict access to authenticated owner only
  - Proper indexes for high-frequency queries

  ## Triggers
  - Auto-create profile on user signup
  - Auto-update updated_at timestamp

  ## Notes
  - All monetary values stored as NUMERIC(15,2) for INR
  - Month column in budgets uses INTEGER (1-12)
  - Year column in budgets uses INTEGER

  ## Usage
  Run this SQL in your Supabase SQL Editor or via psql to create all tables.
*/

-- =====================================================
-- PROFILES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL DEFAULT '',
  avatar_url text DEFAULT '',
  phone text DEFAULT '',
  monthly_income numeric(15,2) NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'INR',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- =====================================================
-- TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('income', 'expense')),
  amount numeric(15,2) NOT NULL CHECK (amount > 0),
  category text NOT NULL DEFAULT 'Other',
  merchant text NOT NULL DEFAULT '',
  description text DEFAULT '',
  date date NOT NULL DEFAULT CURRENT_DATE,
  receipt_url text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(user_id, category);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(user_id, type);

-- Enable RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON transactions;

-- Create policies
CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON transactions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
  ON transactions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
  ON transactions FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- BUDGETS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text NOT NULL,
  monthly_limit numeric(15,2) NOT NULL CHECK (monthly_limit > 0),
  month integer NOT NULL CHECK (month >= 1 AND month <= 12),
  year integer NOT NULL,
  alert_80_sent boolean NOT NULL DEFAULT false,
  alert_90_sent boolean NOT NULL DEFAULT false,
  alert_100_sent boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (user_id, category, month, year)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user_month_year ON budgets(user_id, month, year);
CREATE INDEX IF NOT EXISTS idx_budgets_category ON budgets(user_id, category);

-- Enable RLS
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own budgets" ON budgets;
DROP POLICY IF EXISTS "Users can insert own budgets" ON budgets;
DROP POLICY IF EXISTS "Users can update own budgets" ON budgets;
DROP POLICY IF EXISTS "Users can delete own budgets" ON budgets;

-- Create policies
CREATE POLICY "Users can view own budgets"
  ON budgets FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own budgets"
  ON budgets FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own budgets"
  ON budgets FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own budgets"
  ON budgets FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- RECEIPT SCANS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS receipt_scans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url text,
  raw_text text DEFAULT '',
  extracted_amount numeric(15,2),
  extracted_merchant text DEFAULT '',
  extracted_date date,
  extracted_category text DEFAULT '',
  confidence_score numeric(5,4) DEFAULT 0,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  transaction_id uuid REFERENCES transactions(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_receipt_scans_user_id ON receipt_scans(user_id);
CREATE INDEX IF NOT EXISTS idx_receipt_scans_status ON receipt_scans(status);
CREATE INDEX IF NOT EXISTS idx_receipt_scans_created ON receipt_scans(created_at DESC);

-- Enable RLS
ALTER TABLE receipt_scans ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own receipt scans" ON receipt_scans;
DROP POLICY IF EXISTS "Users can insert own receipt scans" ON receipt_scans;
DROP POLICY IF EXISTS "Users can update own receipt scans" ON receipt_scans;
DROP POLICY IF EXISTS "Users can delete own receipt scans" ON receipt_scans;

-- Create policies
CREATE POLICY "Users can view own receipt scans"
  ON receipt_scans FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own receipt scans"
  ON receipt_scans FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own receipt scans"
  ON receipt_scans FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own receipt scans"
  ON receipt_scans FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  budget_id uuid REFERENCES budgets(id) ON DELETE SET NULL,
  type text NOT NULL DEFAULT 'budget_alert' CHECK (type IN ('budget_80', 'budget_90', 'budget_100', 'info')),
  title text NOT NULL DEFAULT '',
  message text NOT NULL DEFAULT '',
  email_sent boolean NOT NULL DEFAULT false,
  read boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;

-- Create policies
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- STOCK RECOMMENDATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS stock_recommendations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recommendation_text text NOT NULL DEFAULT '',
  stocks jsonb NOT NULL DEFAULT '[]',
  mutual_funds jsonb NOT NULL DEFAULT '[]',
  risk_profile text NOT NULL DEFAULT 'moderate' CHECK (risk_profile IN ('conservative', 'moderate', 'aggressive')),
  generated_at timestamptz DEFAULT now(),
  month integer NOT NULL,
  year integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_stock_rec_user_id ON stock_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_stock_rec_month_year ON stock_recommendations(user_id, month, year);
CREATE INDEX IF NOT EXISTS idx_stock_rec_generated ON stock_recommendations(generated_at DESC);

-- Enable RLS
ALTER TABLE stock_recommendations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own stock recommendations" ON stock_recommendations;
DROP POLICY IF EXISTS "Users can insert own stock recommendations" ON stock_recommendations;
DROP POLICY IF EXISTS "Users can update own stock recommendations" ON stock_recommendations;
DROP POLICY IF EXISTS "Users can delete own stock recommendations" ON stock_recommendations;

-- Create policies
CREATE POLICY "Users can view own stock recommendations"
  ON stock_recommendations FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own stock recommendations"
  ON stock_recommendations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own stock recommendations"
  ON stock_recommendations FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own stock recommendations"
  ON stock_recommendations FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function: Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Auto-create profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers: updated_at for each table
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_budgets_updated_at ON budgets;
CREATE TRIGGER update_budgets_updated_at
  BEFORE UPDATE ON budgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_receipt_scans_updated_at ON receipt_scans;
CREATE TRIGGER update_receipt_scans_updated_at
  BEFORE UPDATE ON receipt_scans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- GRANT PERMISSIONS FOR EDGE FUNCTIONS
-- =====================================================

-- Allow service role to manage all tables (for edge functions)
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE profiles IS 'User profile data extending auth.users';
COMMENT ON TABLE transactions IS 'Income and expense transactions in INR';
COMMENT ON TABLE budgets IS 'Monthly category-based budget limits with alert tracking';
COMMENT ON TABLE receipt_scans IS 'AI-processed receipt records from Groq vision';
COMMENT ON TABLE notifications IS 'Budget alert and system notification history';
COMMENT ON TABLE stock_recommendations IS 'AI-generated Indian stock and MF recommendations';

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

alter table transactions enable row level security;
drop policy if exists "Users see own transactions" on transactions;
create policy "Users see own transactions" on transactions
  for all using (auth.uid() = user_id);








alter table budgets enable row level security;
drop policy if exists "Users see own budgets" on budgets;
create policy "Users see own budgets" on budgets
  for all using (auth.uid() = user_id);

alter table notifications enable row level security;
drop policy if exists "Users see own notifications" on notifications;
create policy "Users see own notifications" on notifications
  for all using (auth.uid() = user_id);

alter table profiles enable row level security;
drop policy if exists "Users see own profile" on profiles;
create policy "Users see own profile" on profiles
  for all using (auth.uid() = id);
