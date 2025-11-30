# Supabase Setup Guide

This guide will help you set up Supabase for Agile Self with Google Authentication.

## Prerequisites

- A Google Cloud account (for OAuth)
- A Supabase account (free tier works)

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign in with GitHub
4. Click "New Project"
5. Fill in:
   - **Name**: `agile-self` (or your preferred name)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to your users
6. Click "Create new project"
7. Wait 2-3 minutes for setup to complete

## Step 2: Configure Google OAuth

### 2.1 Get Supabase OAuth Callback URL

1. In your Supabase project dashboard
2. Go to **Authentication** → **URL Configuration**
3. Copy the "Site URL" (default: `http://localhost:3000`)
4. Note the redirect URL format: `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`

### 2.2 Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API:
   - Go to **APIs & Services** → **Library**
   - Search for "Google+ API"
   - Click **Enable**
4. Create OAuth credentials:
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth client ID**
   - Application type: **Web application**
   - Name: `Agile Self`
   - **Authorized JavaScript origins**:
     - `http://localhost:3000` (for development)
     - `https://[YOUR-PROJECT-REF].supabase.co`
   - **Authorized redirect URIs**:
     - `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`
   - Click **Create**
5. Copy the **Client ID** and **Client Secret**

### 2.3 Configure Google Provider in Supabase

1. In Supabase dashboard → **Authentication** → **Providers**
2. Find **Google** and toggle it **ON**
3. Paste your Google **Client ID**
4. Paste your Google **Client Secret**
5. Click **Save**

## Step 3: Run Database Schema

1. In Supabase dashboard → **SQL Editor**
2. Click **New Query**
3. Copy the contents of `supabase/schema.sql` from this project
4. Paste into the SQL editor
5. Click **Run** (or press ⌘/Ctrl + Enter)
6. Verify success (should see "Success. No rows returned")

The schema creates:
- ✅ `retrospectives` table
- ✅ `actions` table
- ✅ `user_preferences` table
- ✅ Row Level Security (RLS) policies
- ✅ Indexes for performance
- ✅ Auto-update timestamps
- ✅ Auto-create user preferences on signup

## Step 4: Get API Credentials

1. In Supabase dashboard → **Project Settings** (gear icon)
2. Go to **API** section
3. Copy the following:
   - **Project URL** (under "Project URL")
   - **anon public** key (under "Project API keys")

## Step 5: Configure Environment Variables

1. In your project root, create `.env.local`:

```bash
cp .env.example .env.local
```

2. Edit `.env.local` and add your credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

⚠️ **Important**: Never commit `.env.local` to git!

## Step 6: Test the Integration

1. Start your development server:
```bash
npm run dev
```

2. Open [http://localhost:3000/login](http://localhost:3000/login)

3. Click "Continue with Google"

4. Sign in with your Google account

5. You should be redirected back to the app

6. Verify in Supabase dashboard:
   - Go to **Authentication** → **Users**
   - You should see your Google account

## Step 7: Update Redirect URLs (Production)

When deploying to production (e.g., Vercel):

1. Deploy your app and get the production URL

2. Update Google OAuth credentials:
   - Add production URL to **Authorized JavaScript origins**
   - Add `https://your-app.vercel.app/auth/callback` to **Authorized redirect URIs**

3. Update Supabase URL Configuration:
   - Go to **Authentication** → **URL Configuration**
   - Add your production URL to **Site URL**
   - Add `https://your-app.vercel.app/**` to **Redirect URLs**

4. Update Vercel environment variables:
   - Add `NEXT_PUBLIC_SUPABASE_URL`
   - Add `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Troubleshooting

### "Invalid redirect URI" error

- Check that your redirect URI in Google Cloud Console exactly matches:
  `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`
- Check that localhost:3000 is added to Authorized JavaScript origins

### "User not found" after sign-in

- Check that RLS policies are created (run schema.sql again)
- Check browser console for errors
- Verify user appears in Supabase Authentication → Users

### "Failed to fetch" error

- Check that environment variables are set correctly
- Restart dev server after changing `.env.local`
- Verify Supabase project is running (not paused)

### Data not syncing

- Check browser console for errors
- Verify RLS policies allow user to access their data
- Check Network tab for failed requests

## Database Schema Verification

Run this query in SQL Editor to verify tables exist:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

You should see:
- retrospectives
- actions
- user_preferences

## Testing RLS Policies

Run this query (replace `user_id_here` with your actual user ID from auth.users):

```sql
-- Get your user ID first
SELECT id, email FROM auth.users;

-- Test retrospectives access
SELECT * FROM retrospectives WHERE user_id = 'your-user-id-here';
```

If RLS is working correctly, you can only see your own data.

## Next Steps

- ✅ Users can sign in with Google
- ✅ Data syncs to Supabase
- ✅ Row Level Security protects user data
- 🔜 Add email reminders
- 🔜 Add real-time sync
- 🔜 Add data export from Supabase

## Support

If you encounter issues:
1. Check Supabase logs: Dashboard → Logs
2. Check browser console for JavaScript errors
3. Verify all environment variables are set
4. Ensure schema.sql ran successfully

For Supabase-specific issues, see [Supabase Documentation](https://supabase.com/docs)
