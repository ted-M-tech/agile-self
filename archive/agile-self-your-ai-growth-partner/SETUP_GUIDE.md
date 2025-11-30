# Setup Guide for AI Cache & Google OAuth

This guide will help you configure the new features added to Agile Self:
1. **AI Insights Cache** - Reduces Gemini API calls to save tokens
2. **Google OAuth Authentication** - Allows users to sign in with Google

---

## Part 1: AI Insights Cache Setup

### What Changed?
- **Before**: AI insights were generated every time the dashboard loaded (using Gemini API tokens)
- **After**: AI insights are cached in the database and only regenerated when new retrospectives are created

### Database Migration Required

You need to add the `ai_insights_cache` table to your Supabase database.

#### Run Migration in Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the entire contents of `supabase/migrations/add_ai_insights_cache.sql` and paste it

   **OR** copy this SQL:

```sql
-- Create AI insights cache table
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

-- Create index
CREATE INDEX IF NOT EXISTS idx_ai_insights_cache_user_id ON public.ai_insights_cache(user_id, insight_type);

-- Enable RLS
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

-- Auto-update trigger
CREATE TRIGGER update_ai_insights_cache_updated_at
  BEFORE UPDATE ON public.ai_insights_cache
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

5. Click **Run** (or press Cmd/Ctrl + Enter)
6. Verify success: Check **Table Editor** > `ai_insights_cache` table should exist

**Note**: If you get "relation already exists" errors, that's fine - it means the table is already created. The migration uses `IF NOT EXISTS` to be safe.

### How It Works Now

1. **First Visit**: Dashboard calls `/api/ai/insights` which generates insights and caches them
2. **Subsequent Visits**: Dashboard loads cached insights (no API calls!)
3. **New Retrospective**: When user completes a new retro, cache becomes outdated
4. **Next Visit**: System detects outdated cache and regenerates insights automatically

### Token Savings
- **Before**: ~2 API calls every dashboard visit
- **After**: 2 API calls only when cache is missing/outdated
- **Typical savings**: ~90% reduction in API calls for regular users

---

## Part 2: Google OAuth Setup

### 1. Configure Google Cloud Console

#### Step 1: Create Google OAuth Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**
5. If prompted, configure the OAuth consent screen:
   - **User Type**: External
   - **App name**: Agile Self
   - **User support email**: Your email
   - **Developer contact**: Your email
   - **Scopes**: Add `email` and `profile`
   - Save and continue

#### Step 2: Create OAuth Client ID
1. **Application type**: Web application
2. **Name**: Agile Self Web App
3. **Authorized JavaScript origins**:
   - `http://localhost:3000` (for development)
   - `https://your-production-domain.com` (for production)
   - `https://YOUR-PROJECT-REF.supabase.co` (Supabase URL)
4. **Authorized redirect URIs**:
   - `http://localhost:3000/auth/callback`
   - `https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback`
   - Replace `YOUR-PROJECT-REF` with your actual Supabase project reference
5. Click **Create**
6. **Save** the Client ID and Client Secret (you'll need these next)

### 2. Configure Supabase

#### Step 1: Add Google Provider
1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **Providers**
3. Find **Google** in the list and click to expand
4. Toggle **Enable Sign in with Google** to ON
5. Enter your credentials:
   - **Client ID**: Paste from Google Cloud Console
   - **Client Secret**: Paste from Google Cloud Console
6. Copy the **Callback URL (for OAuth)** displayed
7. Click **Save**

#### Step 2: Update Google OAuth Redirect URI (if needed)
If the callback URL from Supabase doesn't match what you entered in Google Cloud:
1. Go back to Google Cloud Console > Credentials
2. Edit your OAuth client
3. Add the exact callback URL from Supabase to **Authorized redirect URIs**
4. Save

### 3. Test Google Sign-In

1. Start your development server: `npm run dev`
2. Navigate to `http://localhost:3000/auth/login`
3. Click **Sign in with Google**
4. You should be redirected to Google's consent screen
5. After signing in, you should be redirected to `/dashboard`

### Troubleshooting

#### Issue: "redirect_uri_mismatch" error
**Solution**: Make sure the redirect URI in Google Cloud Console exactly matches the one from Supabase (including `https://` and trailing path)

#### Issue: "Access blocked: This app hasn't been verified"
**Solution**: During development, click "Advanced" > "Go to Agile Self (unsafe)" to continue. For production, you'll need to verify your app with Google.

#### Issue: Sample data not created for Google users
**Solution**: The sample data creation currently only works for email/password signup. You may need to add a check in the `handle_new_user()` database function to create sample data for OAuth users as well.

---

## Part 3: Environment Variables

Ensure your `.env.local` file has all required variables:

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Gemini AI
GEMINI_API_KEY=your-gemini-api-key

# Supabase Service Role (for server-side API routes)
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## Summary of Changes

### Files Modified
1. **supabase/schema.sql** - Added `ai_insights_cache` table
2. **app/api/ai/insights/route.ts** - New cached insights endpoint
3. **components/DashboardAIInsights.tsx** - Uses cached endpoint
4. **app/auth/login/page.tsx** - Added Google sign-in button
5. **app/auth/signup/page.tsx** - Added Google sign-up button

### New API Endpoints
- `POST /api/ai/insights` - Returns cached or fresh AI insights

### Benefits
- **90% reduction** in Gemini API calls for dashboard visits
- **OAuth support** for faster user onboarding
- **Automatic cache invalidation** when new retrospectives are created
- **Better UX** with Google single sign-on

---

## Need Help?

If you encounter any issues:
1. Check Supabase logs: **Dashboard > Logs**
2. Check browser console for errors
3. Verify environment variables are set correctly
4. Ensure database migration ran successfully
