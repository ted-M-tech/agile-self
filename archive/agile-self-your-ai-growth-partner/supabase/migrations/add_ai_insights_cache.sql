-- Migration: Add AI Insights Cache Table
-- Date: 2025-01-24
-- Description: Adds caching for AI-generated insights to reduce API calls

-- =====================================================
-- AI INSIGHTS CACHE TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_insights_cache (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  insight_type TEXT CHECK (insight_type IN ('patterns', 'sentiment', 'combined')) NOT NULL,
  data JSONB NOT NULL,
  retrospective_count INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, insight_type)
);

-- =====================================================
-- INDEX
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_ai_insights_cache_user_id
  ON public.ai_insights_cache(user_id, insight_type);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE public.ai_insights_cache ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own insights cache"
  ON public.ai_insights_cache FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own insights cache"
  ON public.ai_insights_cache FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own insights cache"
  ON public.ai_insights_cache FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own insights cache"
  ON public.ai_insights_cache FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- AUTO-UPDATE TRIGGER
-- =====================================================
CREATE TRIGGER update_ai_insights_cache_updated_at
  BEFORE UPDATE ON public.ai_insights_cache
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VERIFICATION
-- =====================================================
-- Uncomment to verify the table was created successfully:
-- SELECT EXISTS (
--   SELECT FROM information_schema.tables
--   WHERE table_schema = 'public'
--   AND table_name = 'ai_insights_cache'
-- ) AS table_exists;
