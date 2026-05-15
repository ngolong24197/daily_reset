# Daily Reset

Lightweight daily habit app — morning spark, brain kick, and daily reflection.

## Features

- **Morning Spark** — Daily inspirational quote with meaning and favorites
- **Brain Kick** — Daily quiz to challenge your mind (replay with new questions)
- **Daily Reflection** — Track your mood and journal entries
- **Streak Tracking** — Build consistency with streaks and milestones
- **Google Sign-In** — Cloud backup for favorites and reflections
- **Favorites** — Save and view favorite quotes (10 free, unlimited with Premium)
- **Reflection History** — Browse past mood entries
- **Notifications** — Morning and evening reminders with custom time
- **Premium** — Remove ads, unlimited favorites, content refresh

## Tech Stack

- **Flutter 3.11+** with **Riverpod** for state management
- **Hive CE** for local persistence
- **Firebase Auth** + **Google Sign-In** for authentication
- **Cloud Firestore** for cloud backup
- **Google AdMob** for monetization
- **Google Play Billing** for premium purchases

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- Android Studio / VS Code
- A Firebase project (see setup below)

### Install

```bash
git clone https://github.com/ngolong24197/daily_reset.git
cd daily_reset/AutoTrading
flutter pub get
```

### Run

```bash
flutter run
```

### Build Release

```bash
flutter build apk --release
```

The release APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Google Sign-In)
3. Enable **Cloud Firestore** (start in test mode, then add security rules)
4. Add your Android app with package name `com.dailyreset.daily_reset`
5. Add your SHA-1 fingerprint
6. Download `google-services.json` and place it in `android/app/`
7. Set Firestore security rules (see `docs/play_store_deploy.md`)

## AdMob Setup

1. Create an AdMob account at [apps.admob.com](https://apps.admob.com)
2. Create Banner and Interstitial ad units
3. Update ad unit IDs in `lib/core/services/ad/ad_service.dart`
4. Update app ID in `android/app/src/main/AndroidManifest.xml`

## Project Structure

```
lib/
  main.dart                        # App entry point with restart mechanism
  core/
    providers.dart                  # Riverpod providers and notifiers
    constants/
      app_theme.dart                # Colors and theme definitions
      content_urls.dart             # Remote content URLs
    services/
      ad/ad_service.dart            # AdMob banner and interstitial
      auth/auth_service.dart        # Google Sign-In via Firebase Auth
      cloud/cloud_backup_service.dart # Firestore backup/restore
      content/content_service.dart  # Quote and trivia selection
      content/date_seeder.dart      # Deterministic date-seeded random
      notification/notification_service.dart
      persistence/persistence_service.dart # Hive local storage
      premium/premium_service.dart  # In-app purchase
      sound/sound_service.dart      # Chime effects
    models/
      quote.dart
      trivia.dart
      mood.dart
      streak.dart
  features/
    home/home_page.dart
    morning/morning_page.dart       # Daily quote
    brain_kick/brain_kick_page.dart # Daily quiz
    reflection/reflection_page.dart  # Mood tracking
    reflection/reflection_history_page.dart
    favorites/favorites_page.dart
    settings/settings_page.dart
    settings/privacy_policy_page.dart
    premium/premium_page.dart
```

## Testing

```bash
flutter test
```

## Download

Download the latest APK from [GitHub Releases](https://github.com/ngolong24197/daily_reset/releases).

## License

All rights reserved.