-- Life Planner Pro — Supabase Setup
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/ajxbatceyclfennrtbbz/sql

-- 1. Create user_data table
CREATE TABLE IF NOT EXISTS public.user_data (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  section     text        NOT NULL,
  key         text        NOT NULL,
  value       text,
  updated_at  timestamptz DEFAULT now(),
  CONSTRAINT  user_data_unique UNIQUE (user_id, section, key)
);

-- 2. Index for fast per-user lookups
CREATE INDEX IF NOT EXISTS idx_user_data_user_id ON public.user_data (user_id);

-- 3. Enable Row Level Security
ALTER TABLE public.user_data ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policy: users can only touch their own rows
CREATE POLICY "Users manage own data"
  ON public.user_data
  FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. Auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_user_data_updated_at
  BEFORE UPDATE ON public.user_data
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Done! Your user_data table is ready.
