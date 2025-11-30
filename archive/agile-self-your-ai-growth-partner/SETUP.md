# Agile Self - Setup & Deployment Guide

This guide will help you set up the development environment and deploy Agile Self to Vercel.

## Prerequisites

- Node.js 18+ installed
- npm or yarn package manager
- Git
- Supabase account (free tier: https://supabase.com)
- Vercel account (free tier: https://vercel.com)

---

## Step 1: Supabase Setup

### 1.1 Create Supabase Project

1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Fill in project details:
   - **Name**: agile-self (or your preferred name)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose closest to your location
   - **Plan**: Free tier is sufficient for MVP
4. Wait 2-3 minutes for project to provision

### 1.2 Run Database Schema

1. In your Supabase project dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `supabase/schema.sql` from this repo
4. Paste into the SQL editor
5. Click **Run** (or press Cmd/Ctrl + Enter)
6. You should see "Success. No rows returned" - this is correct!

### 1.3 Verify Database Setup

1. Go to **Table Editor** in Supabase dashboard
2. You should see these tables:
   - users
   - user_preferences
   - retrospectives
   - keeps
   - problems
   - tries
   - actions

### 1.4 Get Supabase Credentials

1. Go to **Project Settings** → **API**
2. Copy these values (you'll need them later):
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (under "Project API keys")

### 1.5 Configure Authentication

1. Go to **Authentication** → **Providers**
2. Enable **Email** provider (should be enabled by default)
3. Optional: Enable social providers (Google, GitHub, etc.)
   - For Google: You'll need to create OAuth credentials in Google Cloud Console
   - For GitHub: Create OAuth app in GitHub settings

---

## Step 2: Local Development Setup

### 2.1 Clone and Install Dependencies

```bash
cd /Users/tetsuya/Develop/agile-self-your-ai-growth-partner

# Install dependencies
npm install
# or
yarn install
```

### 2.2 Environment Variables

Create a `.env.local` file in the project root:

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here

# Optional: For development
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

**Important**: Replace the values with your actual Supabase credentials from Step 1.4

### 2.3 Start Development Server

```bash
npm run dev
# or
yarn dev
```

Open http://localhost:3000 in your browser.

---

## Step 3: Deploy to Vercel

### 3.1 Connect GitHub Repository (Recommended)

1. Push your code to GitHub:
   ```bash
   git add .
   git commit -m "Initial commit: Agile Self MVP"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/agile-self.git
   git push -u origin main
   ```

2. Go to https://vercel.com/new
3. Click "Import Git Repository"
4. Select your `agile-self` repository
5. Vercel will auto-detect Next.js settings

### 3.2 Configure Environment Variables in Vercel

1. In the Vercel deployment screen, scroll to **Environment Variables**
2. Add these variables:
   ```
   NEXT_PUBLIC_SUPABASE_URL = https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY = your-anon-key-here
   NEXT_PUBLIC_APP_URL = https://your-app.vercel.app
   ```
3. Click **Deploy**

### 3.3 Wait for Deployment

- Vercel will build and deploy your app (~2-3 minutes)
- You'll get a URL like: `https://agile-self.vercel.app`

### 3.4 Configure Supabase Redirect URLs

1. Go back to Supabase dashboard → **Authentication** → **URL Configuration**
2. Add your Vercel URL to **Site URL**:
   ```
   https://your-app.vercel.app
   ```
3. Add to **Redirect URLs**:
   ```
   https://your-app.vercel.app/auth/callback
   http://localhost:3000/auth/callback
   ```

---

## Step 4: Test Your Deployment

### 4.1 Create Test Account

1. Visit your Vercel URL: `https://your-app.vercel.app`
2. Click "Sign Up"
3. Enter email and password
4. Check your email for confirmation (if email confirmation is enabled)
5. Log in

### 4.2 Test KPTA Flow

1. Click "New Retrospective"
2. Fill in Keep, Problem, Try sections
3. Create Action items
4. Complete the retrospective
5. Check History tab

### 4.3 Verify Database

1. Go to Supabase → **Table Editor**
2. Check `retrospectives` table - you should see your entry
3. Check `keeps`, `problems`, `tries`, `actions` tables

---

## Step 5: Continuous Deployment

Once connected to GitHub, Vercel will automatically:
- Deploy on every push to `main` branch
- Create preview deployments for pull requests
- Run builds and show deployment status

### Making Updates

```bash
# Make changes to code
git add .
git commit -m "Add new feature"
git push

# Vercel automatically deploys!
```

---

## Troubleshooting

### Issue: "Failed to fetch" or CORS errors

**Solution**: Check that Supabase URL and keys are correct in `.env.local` and Vercel environment variables.

### Issue: Can't sign up/login

**Solution**:
1. Verify redirect URLs in Supabase (Step 3.4)
2. Check that email provider is enabled in Supabase
3. Look for errors in browser console (F12)

### Issue: Database queries fail

**Solution**:
1. Verify Row Level Security (RLS) policies are enabled (they're in schema.sql)
2. Check that you're logged in (auth.uid() must exist)
3. Test queries in Supabase SQL Editor

### Issue: Build fails on Vercel

**Solution**:
1. Check build logs in Vercel dashboard
2. Verify all dependencies are in package.json
3. Ensure TypeScript types are correct

### Issue: Environment variables not working

**Solution**:
1. Verify variable names start with `NEXT_PUBLIC_` for client-side access
2. Redeploy after adding/changing environment variables
3. Clear browser cache

---

## Database Maintenance

### Backup Database

```bash
# In Supabase dashboard
# Go to Database → Backups
# Enable automatic daily backups (free tier: 7 days retention)
```

### View Logs

```bash
# Supabase dashboard → Logs
# See real-time database queries and auth events
```

### Monitor Usage

```bash
# Supabase dashboard → Settings → Usage
# Track database size, API calls, bandwidth
```

---

## Security Checklist

- [x] Row Level Security (RLS) enabled on all tables
- [x] Environment variables not committed to Git (`.env.local` in `.gitignore`)
- [x] Supabase anon key is safe to expose (RLS protects data)
- [ ] Enable email confirmation in Supabase (Authentication → Settings)
- [ ] Set up password requirements (Authentication → Settings)
- [ ] Configure rate limiting for auth (Supabase has default limits)

---

## Next Steps

### Optional Enhancements

1. **Custom Domain**: Add your own domain in Vercel settings
2. **Analytics**: Add Google Analytics or PostHog
3. **Error Tracking**: Set up Sentry for error monitoring
4. **Email Templates**: Customize Supabase auth emails
5. **PWA**: Add Progressive Web App manifest for mobile experience

### Phase 2: AI Features

When ready to add AI features:
1. Create Gemini API account (Google AI)
2. Add API key to Vercel environment variables
3. Create Supabase Edge Function for AI processing
4. Update premium tier logic

---

## Support Resources

- **Next.js Docs**: https://nextjs.org/docs
- **Supabase Docs**: https://supabase.com/docs
- **Vercel Docs**: https://vercel.com/docs
- **Tailwind CSS**: https://tailwindcss.com/docs

---

## Local Development Commands

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Start production server locally
npm run start

# Lint code
npm run lint

# Type check
npm run type-check
```

---

**Last Updated**: 2025-10-23
**Version**: 1.0
