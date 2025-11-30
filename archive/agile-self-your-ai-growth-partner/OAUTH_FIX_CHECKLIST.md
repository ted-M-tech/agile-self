# 🔧 Fix "Redirects to Localhost" - Quick Checklist

## The Problem
When you sign in with Google on Vercel, it redirects you back to `http://localhost:3000` instead of your production URL.

## The Solution (3 steps, 5 minutes)

---

### ✅ Step 1: Update Google Cloud Console

**What to do:** Add your Vercel URL to authorized redirect URIs

1. Open [Google Cloud Console](https://console.cloud.google.com/)
2. Go to: **APIs & Services** → **Credentials**
3. Click your OAuth 2.0 Client ID
4. Find **Authorized redirect URIs** section
5. Click **+ ADD URI**
6. Add these two URIs:

   ```
   https://YOUR-VERCEL-APP.vercel.app/auth/callback
   https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback
   ```

   **Find your Vercel URL:** Check your Vercel dashboard or deployment URL
   **Find your Supabase URL:** Supabase Dashboard → Settings → API

7. Keep the localhost URL for local development:
   ```
   http://localhost:3000/auth/callback
   ```

8. Click **SAVE**

**Example of what it should look like:**
```
✅ http://localhost:3000/auth/callback
✅ https://agile-self-xyz.vercel.app/auth/callback
✅ https://abcdefghijk.supabase.co/auth/v1/callback
```

---

### ✅ Step 2: Update Supabase Site URL (MOST IMPORTANT!)

**What to do:** Tell Supabase to use your Vercel URL, not localhost

1. Open [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to: **Settings** → **Authentication**
4. Scroll to **Site URL**
5. Change from:
   ```
   ❌ http://localhost:3000
   ```
   To:
   ```
   ✅ https://YOUR-VERCEL-APP.vercel.app
   ```

6. Scroll to **Redirect URLs** section
7. Add these:
   ```
   https://YOUR-VERCEL-APP.vercel.app/**
   http://localhost:3000/**
   ```

8. Click **Save**

**This is the #1 reason for localhost redirects! Don't skip this step.**

---

### ✅ Step 3: Redeploy on Vercel

**What to do:** Make sure your latest code is deployed

1. Go to your [Vercel Dashboard](https://vercel.com/dashboard)
2. Find your project
3. Click **Deployments**
4. Click **Redeploy** on the latest deployment

   OR just push to Git if you have auto-deploy enabled

5. Wait for build to complete

---

## 🎯 Test It

1. Visit your Vercel app: `https://YOUR-VERCEL-APP.vercel.app`
2. Click **Sign in with Google**
3. Complete Google authentication
4. **You should land on:** `https://YOUR-VERCEL-APP.vercel.app/dashboard`
5. **NOT:** `http://localhost:3000/dashboard`

---

## ⚡ Quick Visual Guide

```
Before Fix:
User clicks Google sign-in on Vercel
  ↓
Google authenticates
  ↓
❌ Redirects to http://localhost:3000/dashboard
  ↓
Page doesn't load (not running locally)

After Fix:
User clicks Google sign-in on Vercel
  ↓
Google authenticates
  ↓
✅ Redirects to https://YOUR-APP.vercel.app/dashboard
  ↓
Dashboard loads successfully!
```

---

## 🔍 Verification Checklist

Check all these:

**Google Cloud Console:**
- [ ] Vercel callback URL added to authorized redirect URIs
- [ ] Supabase callback URL is in authorized redirect URIs
- [ ] No typos in URLs

**Supabase:**
- [ ] Site URL is set to Vercel domain (NOT localhost)
- [ ] Redirect URLs include Vercel domain
- [ ] Changes are saved

**Vercel:**
- [ ] Latest code is deployed
- [ ] Environment variables are set
- [ ] Deployment status is "Ready"

**Testing:**
- [ ] Tested Google sign-in on production URL
- [ ] Verified redirect goes to production domain
- [ ] Successfully logged in and reached dashboard

---

## 🆘 Still Not Working?

### Check Supabase Site URL Again

**This is the #1 cause of issues!**

Go to: Supabase Dashboard → Settings → Authentication → Site URL

Should be:
```
✅ https://YOUR-VERCEL-APP.vercel.app
```

NOT:
```
❌ http://localhost:3000
❌ https://localhost:3000
❌ (empty)
```

### Clear Your Browser Cache

1. Open DevTools (F12)
2. Right-click the refresh button
3. Click "Empty Cache and Hard Reload"

### Check Browser Console

1. Open DevTools (F12) on your Vercel app
2. Click Google sign-in
3. Check for errors in Console tab
4. Look at Network tab for redirect URLs

### Wait a Few Minutes

Sometimes OAuth changes take 1-2 minutes to propagate. Try:
1. Wait 2 minutes after saving Supabase changes
2. Clear browser cache
3. Try again

---

## 💡 Why This Happens

The code uses `window.location.origin` which automatically detects the current domain:
- Development: `http://localhost:3000`
- Production: `https://YOUR-VERCEL-APP.vercel.app`

However, **Supabase** needs to be configured to allow the production domain, otherwise it defaults to localhost!

---

## ✅ Done!

After completing these 3 steps, your Google OAuth will work perfectly on Vercel! 🎉

**Questions?** Check the full guide in `DEPLOYMENT_GUIDE.md`
