# Daily Reset — Play Store Deployment Checklist

## Project Overview

Daily Reset is a Flutter wellness app with three daily features: Morning Spark (inspirational quote), Brain Kick (quiz), and Daily Reflection (mood tracking). It uses Firebase Auth + Firestore for cloud backup, Hive for local storage, AdMob for monetization, and Google Play Billing for premium purchases.

**Repo**: https://github.com/ngolong24197/daily_reset
**Package name**: `com.dailyreset.daily_reset`
**Firebase project**: `daily-reset-9a1e6`
**Current version**: 1.0.0+1

---

## Current Status (as of 2026-05-15)

### DONE
- [x] Firebase project created (`daily-reset-9a1e6`)
- [x] Firebase Auth enabled (Google Sign-In)
- [x] Cloud Firestore enabled
- [x] Firestore security rules set (users can only read/write their own data)
- [x] SHA-1 fingerprint added to Firebase (`FE:A8:AF:91:D9:A4:16:B6:3A:B4:9B:5A:8E:F1:9D:1F:D7:05:89:18`)
- [x] `google-services.json` configured in `android/app/`
- [x] AdMob account created, real ad unit IDs configured in code
- [x] Release keystore created (`android/app/release-key.jks`)
- [x] Keystore credentials moved to `key.properties` (gitignored)
- [x] Privacy policy page added in app (Settings > Privacy Policy)
- [x] Release APK built and uploaded to GitHub Releases (v1.0.0)
- [x] Google Play Console account created
- [x] App submitted to Play Console — **currently under review**

### IN PROGRESS
- [ ] Play Console review (waiting for Google approval)

### NOT STARTED
- [ ] In-app product setup in Play Console
- [ ] Privacy policy hosted URL (required by Play Console and Google Sign-In)
- [ ] App content rating questionnaire in Play Console
- [ ] AdMob app-ads.txt setup
- [ ] Firestore indexing (if needed for queries)
- [ ] Post-launch monitoring setup

---

## Remaining Steps

### 1. Play Console Review Follow-up

Once the review is complete:
- If **approved**: proceed to remaining steps below
- If **rejected**: check the rejection reason in Play Console, fix the issue, and resubmit

### 2. In-App Product Setup (Premium Purchase)

The app code references product ID `com.dailyreset.premium` in `lib/core/services/premium/premium_service.dart`.

In Play Console:
1. Go to your app → **Monetize** → **In-app products**
2. Click **Create product**
3. Set:
   - **Product ID**: `com.dailyreset.premium` (must match exactly)
   - **Type**: One-time purchase (NOT subscription)
   - **Name**: Premium Upgrade
   - **Description**: Remove ads, unlimited favorites, and encrypted cloud backup
   - **Price**: $1.99 (or your choice — the app UI currently shows "$2 one-time purchase")
4. Set product status to **Active**

### 3. Privacy Policy URL

Play Console requires a publicly accessible privacy policy URL. The app already has an in-app privacy policy page, but you also need a hosted version.

**Option A — GitHub Pages (free):**
1. Create a file at `docs/privacy-policy.html` in the repo (or use the existing `privacy_policy_page.dart` content)
2. Enable GitHub Pages: repo Settings → Pages → Source: Deploy from branch → `main` → `/docs`
3. The URL will be: `https://ngolong24197.github.io/daily_reset/privacy-policy.html`
4. Add this URL to Play Console under **App content** → **Privacy policy**

**Option B — Use a simple site like privacy-policy-generator.com or termsfeed.com**

After getting the URL, also update the contact email in the privacy policy page (`lib/features/settings/privacy_policy_page.dart`) — currently placeholder `dailyreset.app@gmail.com`.

### 4. App Content Rating

In Play Console → **App content** → **Content rating**:
1. Fill out the IARC questionnaire
2. App category: **Health/Fitness** or **Lifestyle**
3. The app contains no violence, no user-generated content visible to others, no gambling
4. It does contain: **ads** (select yes for advertising)

### 5. Target Audience

In Play Console → **App content** → **Target audience**:
1. Select age range: **18+** or **All ages** (app is suitable for all but has ads)
2. The app is NOT directed at children under 13

### 6. AdMob App-ADS.txt

To maximize ad revenue and avoid ad serving issues:
1. Go to https://apps.admob.com → Apps → Daily Reset → App-ads.txt
2. Follow the instructions to set up app-ads.txt on your website
3. If using GitHub Pages, add the app-ads.txt content to your GitHub Pages site

### 7. Ad Unit Verification

Once the app is live on Play Store, verify ads are working:
1. Install from Play Store (not sideload)
2. Test banner ad appears (currently no banner in UI — consider adding one to home page)
3. Test interstitial ad appears on app exit (non-premium users only)
4. AdMob ad units can take up to 24 hours after first install to start serving real ads

**Note**: The app currently only has interstitial ads on exit. Consider adding a banner ad to the home page or settings page for additional revenue.

### 8. Firestore Indexes

If you add any compound queries later, you may need Firestore indexes. Current queries are simple (single document reads by user ID), so no indexes are needed right now. Check the Firebase Console → Firestore → Indexes if you see query errors in the logs.

### 9. Post-Launch Monitoring

After launch:
- **Crash tracking**: Consider adding Firebase Crashlytics (`firebase_crashlytics` package)
- **Analytics**: Consider adding Firebase Analytics (`firebase_analytics` package)
- **AdMob metrics**: Monitor revenue at https://apps.admob.com → Apps → Daily Reset
- **Play Console metrics**: Monitor installs, crashes, and reviews at Play Console

---

## Key File Locations

| Purpose | Path |
|---------|------|
| Ad service (ad IDs) | `lib/core/services/ad/ad_service.dart` |
| Premium service (product ID) | `lib/core/services/premium/premium_service.dart` |
| Auth service (Google Sign-In) | `lib/core/services/auth/auth_service.dart` |
| Cloud backup service | `lib/core/services/cloud/cloud_backup_service.dart` |
| Persistence service | `lib/core/services/persistence/persistence_service.dart` |
| Content service | `lib/core/services/content/content_service.dart` |
| Providers | `lib/core/providers.dart` |
| App entry point | `lib/main.dart` |
| Android manifest | `android/app/src/main/AndroidManifest.xml` |
| Android build config | `android/app/build.gradle.kts` |
| Keystore credentials | `android/key.properties` (gitignored, on local machine only) |
| Release keystore | `android/app/release-key.jks` (gitignored, on local machine only) |
| ProGuard rules | `android/app/proguard-rules.pro` |
| Privacy policy page | `lib/features/settings/privacy_policy_page.dart` |
| Play Console | https://play.google.com/console |
| Firebase Console | https://console.firebase.google.com/project/daily-reset-9a1e6 |
| AdMob Console | https://apps.admob.com |

## AdMob IDs

| Type | ID |
|------|-----|
| App ID | `ca-app-pub-4165496434380827~9142645423` |
| Banner | `ca-app-pub-4165496434380827/6431510150` |
| Interstitial | `ca-app-pub-4165496434380827/5856795083` |

## Premium Product

| Field | Value |
|-------|-------|
| Product ID | `com.dailyreset.premium` |
| Type | One-time purchase |
| Status | NOT YET CREATED in Play Console |

## Keystore Info

| Field | Value |
|-------|-------|
| Alias | `daily-reset` |
| File | `android/app/release-key.jks` |
| Credentials | `android/key.properties` (gitignored) |

**IMPORTANT**: Back up `release-key.jks` and `key.properties` to a secure location. If you lose the keystore, you cannot update the app on Play Store.