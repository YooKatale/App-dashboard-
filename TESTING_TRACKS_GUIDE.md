# Google Play Store Testing Tracks Guide

## Overview

Google Play Console provides multiple testing tracks to safely test your app before releasing to production. This guide explains how to use each track effectively.

---

## Testing Tracks Available

### 1. Internal Testing
**Best for:** Quick testing with your team
- **Max testers:** 100
- **Review time:** Usually instant (no Google review)
- **Use case:** Daily builds, bug fixes, quick validation

### 2. Closed Testing (Alpha/Beta)
**Best for:** Staged testing with specific groups
- **Max testers:** Unlimited (but you control who joins)
- **Review time:** Usually instant
- **Use case:** Feature testing, user feedback, pre-production validation

### 3. Open Testing
**Best for:** Public beta testing
- **Max testers:** Unlimited (anyone can join)
- **Review time:** Usually instant
- **Use case:** Public beta, gathering feedback from real users

### 4. Production
**Best for:** Live app for all users
- **Max testers:** All Play Store users
- **Review time:** 1-7 days (first release), faster for updates
- **Use case:** Final release to all users

---

## Setting Up Testing Tracks

### Step 1: Access Testing Tracks

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. In the left menu, go to **Testing** → **Internal testing** (or Closed/Open testing)

### Step 2: Create a Release

1. Click **Create new release**
2. Upload your `.aab` file (or `.apk`)
3. Add **Release notes** (what's new in this version)
4. Click **Save**

### Step 3: Add Testers

#### For Internal Testing:
1. Go to **Testers** tab
2. Click **Create email list**
3. Add email addresses of testers
4. Share the opt-in link with testers

#### For Closed Testing:
1. Go to **Testers** tab
2. Choose method:
   - **Email list:** Add specific emails
   - **Google Groups:** Use a Google Group
   - **URL:** Share a link (testers join via link)
3. Set tester limit (optional)

#### For Open Testing:
1. Go to **Testers** tab
2. Set **Countries/regions** (optional, leave empty for worldwide)
3. Share the opt-in link publicly

### Step 4: Review and Rollout

1. Review your release
2. Click **Start rollout to Internal testing** (or appropriate track)
3. Testers will receive an email with opt-in link

---

## Recommended Workflow

### Development → Production Pipeline

```
1. Internal Testing (Team)
   ↓
2. Closed Testing - Alpha (Trusted users)
   ↓
3. Closed Testing - Beta (Larger group)
   ↓
4. Production (Staged rollout: 10% → 50% → 100%)
```

### Example Workflow

**Week 1: Internal Testing**
- Upload version `1.0.1+2` to Internal Testing
- Test with your team (5-10 people)
- Fix critical bugs

**Week 2: Closed Testing - Alpha**
- Upload version `1.0.2+3` to Closed Testing
- Test with 20-50 trusted users
- Gather feedback

**Week 3: Closed Testing - Beta**
- Upload version `1.0.3+4` to Closed Testing (different track)
- Test with 100-500 users
- Final validation

**Week 4: Production**
- Upload version `1.0.4+5` to Production
- Start with 10% rollout
- Monitor for 24-48 hours
- Increase to 50%, then 100%

---

## Managing Multiple Tracks

### Creating Multiple Closed Testing Tracks

You can create multiple Closed Testing tracks (e.g., Alpha, Beta, Staging):

1. Go to **Testing** → **Closed testing**
2. Click **Create new track**
3. Name it (e.g., "Alpha", "Beta", "Staging")
4. Each track can have different versions and testers

### Track Strategy Example

- **Alpha Track:** Latest features, 20 testers, weekly updates
- **Beta Track:** Stable features, 200 testers, bi-weekly updates
- **Staging Track:** Pre-production, 10 testers, daily updates

---

## Version Management Across Tracks

### Important Rules

1. **Version Code must increase** for each upload (even across tracks)
2. **Same version code** can exist in different tracks
3. **Production version code** must be highest when promoting

### Example Version Flow

```
Internal Testing:    1.0.1+2
Closed Testing:      1.0.2+3
Production:          1.0.0+1 (current live)
                     
Next update:
Internal Testing:    1.0.3+4
Closed Testing:      1.0.2+3 (promote from Internal)
Production:          1.0.0+1 (promote from Closed when ready)
```

### Promoting Between Tracks

1. Go to the track with the version you want to promote
2. Click on the release
3. Click **Promote release**
4. Select target track
5. Review and confirm

---

## Best Practices

### ✅ Do's

- **Test thoroughly** in Internal before moving to Closed
- **Use staged rollouts** in Production (10% → 50% → 100%)
- **Monitor crash reports** after each release
- **Gather feedback** from testers
- **Document changes** in release notes
- **Keep version codes sequential** (don't skip numbers)
- **Test on multiple devices** before production

### ❌ Don'ts

- Don't skip testing tracks (Internal → Production is risky)
- Don't release to 100% immediately (use staged rollout)
- Don't ignore crash reports
- Don't forget to update release notes
- Don't use same version code in Production that's in testing

---

## Monitoring and Feedback

### Crash Reports

1. Go to **Quality** → **Android vitals** → **Crashes & ANRs**
2. Monitor crash-free rate (aim for >99%)
3. Fix critical issues before promoting

### User Feedback

1. Go to **Ratings and reviews**
2. Read user feedback from testers
3. Address common issues

### Analytics

1. Go to **Statistics**
2. Monitor:
   - Installations
   - Uninstalls
   - User retention
   - Performance metrics

---

## Quick Reference

### Internal Testing Checklist
- [ ] Build release bundle
- [ ] Upload to Internal Testing
- [ ] Add team members as testers
- [ ] Share opt-in link
- [ ] Test for 1-3 days
- [ ] Fix critical issues
- [ ] Promote to Closed Testing

### Closed Testing Checklist
- [ ] Promote from Internal or upload new version
- [ ] Add testers (email list or URL)
- [ ] Share opt-in link
- [ ] Gather feedback for 1-2 weeks
- [ ] Fix issues
- [ ] Promote to Production when ready

### Production Checklist
- [ ] Promote from Closed Testing
- [ ] Start with 10% rollout
- [ ] Monitor for 24-48 hours
- [ ] Check crash reports
- [ ] Increase to 50% if stable
- [ ] Monitor for 24-48 hours
- [ ] Increase to 100% if stable

---

## Troubleshooting

### "Testers can't see the app"
- Check if they've joined via the opt-in link
- Verify they're in the tester list
- Make sure the release is rolled out (not just saved)

### "Can't promote release"
- Check version code is higher than target track
- Ensure release is rolled out in source track
- Verify no critical issues in crash reports

### "App not updating for testers"
- Testers need to uninstall and reinstall
- Or wait for Play Store to detect update (can take hours)
- Check version code is higher than previous

---

## Example: Setting Up Your First Testing Track

### Internal Testing Setup

1. **Build your app:**
   ```bash
   flutter build appbundle --release
   ```

2. **Go to Play Console:**
   - Testing → Internal testing → Create new release

3. **Upload `app-release.aab`**

4. **Add release notes:**
   ```
   Internal testing build
   - Fixed cart display issue
   - Improved payment flow
   - Performance optimizations
   ```

5. **Save and review**

6. **Go to Testers tab:**
   - Create email list
   - Add: your-email@gmail.com, team-member@gmail.com
   - Copy opt-in link

7. **Share link with testers**

8. **Start rollout**

9. **Testers install:**
   - Click opt-in link
   - Join testing program
   - Install/update app from Play Store

---

## Next Steps

1. Set up Internal Testing track
2. Add your team as testers
3. Upload your first test build
4. Gather feedback
5. Iterate and improve
6. Promote to Closed Testing when stable
7. Finally promote to Production

For more details, see [Google Play Console Help](https://support.google.com/googleplay/android-developer)
