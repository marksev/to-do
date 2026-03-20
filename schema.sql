-- ══════════════════════════════════════════════════════════════
--  DailyDo — Supabase Schema
--  Run this entire file in the Supabase SQL Editor
-- ══════════════════════════════════════════════════════════════

-- 1. TODOS table
CREATE TABLE IF NOT EXISTS todos (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title      TEXT        NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DAILY_LOGS table
CREATE TABLE IF NOT EXISTS daily_logs (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  todo_id    UUID        NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date       DATE        NOT NULL,
  completed  BOOLEAN     NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (todo_id, date)   -- one entry per todo per day
);

-- 3. Enable Row Level Security
ALTER TABLE todos      ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies — users can only see & edit their own rows

-- Todos
CREATE POLICY "todos: select own"
  ON todos FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "todos: insert own"
  ON todos FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "todos: delete own"
  ON todos FOR DELETE USING (auth.uid() = user_id);

-- Daily logs
CREATE POLICY "logs: select own"
  ON daily_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "logs: insert own"
  ON daily_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "logs: update own"
  ON daily_logs FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "logs: delete own"
  ON daily_logs FOR DELETE USING (auth.uid() = user_id);
