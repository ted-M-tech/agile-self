# Deployment Guide - Vercel + Google OAuth

## 🚨 Fixing "Redirects to localhost" Issue

When deploying to Vercel, you need to update your OAuth configuration to use production URLs instead of localhost.

---

## Step 1: Update Google Cloud Console (REQUIRED)

### Add Your Vercel URL to Authorized Redirect URIs

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Click on your OAuth 2.0 Client ID
4. Under **Authorized redirect URIs**, add these URLs:

   ```
   https://YOUR-VERCEL-APP.vercel.app/auth/callback
   https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback
   ```

   **Replace:**
   - `YOUR-VERCEL-APP` with your actual Vercel app name
   - `YOUR-PROJECT-REF` with your Supabase project reference

   **Example:**
   ```
   https://agile-self.vercel.app/auth/callback
   https://abcdefghijklmn.supabase.co/auth/v1/callback
   ```

5. Keep the localhost URLs for development:
   ```
   http://localhost:3000/auth/callback
   ```

6. **Save** your changes

---

## Step 2: Update Supabase Site URL (REQUIRED)

This is the most important step to fix the redirect issue!

### Configure Site URL in Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Settings** → **Authentication** (URL Configuration section)
4. Find **Site URL** field
5. Update it to your production URL:
   ```
   https://YOUR-VERCEL-APP.vercel.app
   ```

6. Under **Redirect URLs**, add:
   ```
   https://YOUR-VERCEL-APP.vercel.app/**
   https://YOUR-VERCEL-APP.vercel.app/dashboard
   http://localhost:3000/**  (for development)
   ```

7. Click **Save**

**Important:** The Site URL tells Supabase which domain to redirect to after OAuth. If it's not set, it defaults to localhost!

---

## Step 3: Verify Environment Variables in Vercel

### Check Vercel Environment Variables

1. Go to your Vercel project dashboard
2. Navigate to **Settings** → **Environment Variables**
3. Verify these are set:

   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://YOUR-PROJECT.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   GEMINI_API_KEY=your-gemini-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```

4. If any are missing, add them and click **Save**
5. **Redeploy** your app for changes to take effect

---

## Step 4: Test the Fix

1. Visit your Vercel app: `https://YOUR-VERCEL-APP.vercel.app`
2. Go to `/auth/login`
3. Click **Sign in with Google**
4. After Google authentication, you should be redirected to:
   ```
   https://YOUR-VERCEL-APP.vercel.app/dashboard
   ```
   **NOT** `http://localhost:3000/dashboard`

---

## 🔍 Troubleshooting

### Still Redirecting to Localhost?

**Check Supabase Site URL:**
```bash
# It should be your Vercel URL, not localhost
Site URL: https://YOUR-VERCEL-APP.vercel.app
```

**Clear Browser Cache:**
```
1. Open DevTools (F12)
2. Right-click refresh button
3. Select "Empty Cache and Hard Reload"
```

### "redirect_uri_mismatch" Error

**This means Google doesn't recognize the redirect URL.**

**Fix:**
1. Go to Google Cloud Console → Credentials
2. Verify the exact Supabase callback URL is in authorized redirect URIs
3. Make sure there are no typos (including https:// and the full path)

### OAuth Works on Localhost but Not on Vercel

**This means Supabase Site URL is still set to localhost.**

**Fix:**
1. Supabase Dashboard → Settings → Authentication
2. Change Site URL to your Vercel domain
3. Save and wait 1-2 minutes for propagation

---

## 📋 Complete Checklist

Before going live, ensure:

- [ ] Google Cloud Console has Vercel redirect URI
- [ ] Supabase Site URL is set to Vercel domain
- [ ] Supabase Redirect URLs include Vercel domain
- [ ] Vercel environment variables are all set
- [ ] App has been redeployed after environment changes
- [ ] Tested Google OAuth on production URL
- [ ] Verified redirect goes to production, not localhost

---

## 🎯 Quick Reference

### URLs You Need

**Google Cloud Console:**
- Authorized Redirect URI: `https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback`
- Authorized Redirect URI: `https://YOUR-VERCEL-APP.vercel.app/auth/callback`

**Supabase:**
- Site URL: `https://YOUR-VERCEL-APP.vercel.app`
- Redirect URL: `https://YOUR-VERCEL-APP.vercel.app/**`

**Vercel:**
- Environment: Production
- All environment variables set
- Domain: `YOUR-VERCEL-APP.vercel.app`

---

## 🚀 Deploy Checklist

When deploying updates:

1. **Push to Git** (if using Git integration)
2. **Vercel auto-deploys** (or trigger manual deployment)
3. **Wait for build** to complete
4. **Test on production** URL
5. **Check browser console** for any errors

---

## 💡 Pro Tips

### Multiple Environments

If you have separate Vercel deployments for staging/production:

**Google Cloud Console:**
- Add redirect URIs for each environment
- Example: `https://agile-self-staging.vercel.app/auth/callback`

**Supabase:**
- Consider separate Supabase projects for staging/production
- Or use a single project with multiple redirect URLs

### Custom Domain

If you use a custom domain on Vercel:

1. Add custom domain to Google OAuth redirect URIs
2. Update Supabase Site URL to custom domain
3. Example: `https://agileself.com` instead of `.vercel.app`

---

## 🆘 Still Having Issues?

### Check the Network Tab

1. Open browser DevTools (F12)
2. Go to Network tab
3. Click Google sign-in
4. Look for the OAuth redirect
5. Check the `redirect_uri` parameter in the request

**It should be:**
```
https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback
```

**Not:**
```
http://localhost:3000/...
```

### Check Supabase Logs

1. Supabase Dashboard → Logs → Auth Logs
2. Look for OAuth-related errors
3. Check if the redirect URL is correct

### Verify the Code

The code now uses `window.location.origin` which automatically detects:
- `http://localhost:3000` in development
- `https://YOUR-VERCEL-APP.vercel.app` in production

This is already fixed in your code! ✅

---

## Summary

The redirect issue happens when:
1. ❌ Supabase Site URL is set to localhost
2. ❌ Google OAuth doesn't have Vercel redirect URI

The fix is:
1. ✅ Set Supabase Site URL to Vercel domain
2. ✅ Add Vercel redirect URI to Google OAuth
3. ✅ Code already uses dynamic `window.location.origin`

After these changes, OAuth will work correctly on production! 🎉
