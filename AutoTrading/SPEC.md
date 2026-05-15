# SPEC — Daily Reset

## Objective

Build a production-ready Flutter daily habit app called **Daily Reset** with 3 daily interactions:
- Morning Spark (daily quote + meaning + save/share)
- Brain Kick (1-3 trivia questions with explanations)
- Daily Reflection (mood selector + journal + AI-like templated response)

Monetized via AdMob interstitial on exit + $2 one-time premium purchase. All data is local (Hive + JSON assets). No APIs.

Target user: **single personal user**.
Deployment: **Android (iOS-ready)**.
Stack: **Flutter 3.41+ | Riverpod 2.4+ | Hive CE**.

---

## Commands

- `flutter run` — launch app in debug
- `flutter test` — run unit + widget tests
- `flutter build apk --release` — generate signed APK
- `dart run build_runner build` — regenerate Hive adapters

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── providers.dart
│   ├── constants/
│   │   ├── ad_ids.dart
│   │   └── app_theme.dart
│   └── services/
│       ├── ad/ad_service.dart
│       ├── notification/notification_service.dart
│       ├── content/content_service.dart
│       ├── content/date_seeder.dart
│       ├── sound/sound_service.dart
│       ├── backup/backup_service.dart
│       ├── backup/crypto_helper.dart
│       ├── premium/premium_service.dart
│       └── persistence/persistence_service.dart
├── features/
│   ├── home/home_page.dart
│   ├── morning/morning_page.dart
│   ├── brain_kick/brain_kick_page.dart
│   ├── reflection/reflection_page.dart
│   ├── settings/settings_page.dart
│   └── premium/premium_page.dart
├── models/
│   ├── quote.dart
│   ├── trivia.dart
│   ├── streak.dart
│   └── mood.dart
└── widgets/
    ├── streak_widget.dart
    ├── quote_card.dart
    └── mood_selector.dart

assets/
├── data/quotes.json (50 quotes)
├── data/trivia.json (100 questions)
├── sounds/chime_short.mp3, chime_medium.mp3, chime_long.mp3
└── animations/streak_fire.json
```

---

## Core Logic

### Date-Seeded Content
`int dateSeed(DateTime d) => d.year * 10000 + d.month * 100 + d.day`
Same date → same quote + trivia on every device via `Random(dateSeed)`.

### Streak Logic
- Today completed → streak++
- Miss day → reset to 0
- Calendar: `Map<String, bool>` (yyyy-MM-dd → completed)
- Milestones: 3=Week1, 7=PowerUser, 30=Master

### Progressive TP (N/A — not a trading app)

### Exit Flow
WillPopScope → "See you tomorrow" dialog → Interstitial ad → Exit
Premium → skip ad, exit immediately
Ad fail → immediate exit (no blocking)

---

## Testing Strategy

- Unit tests: ContentService, DateSeeder, models, crypto
- Widget tests: mood selector, quote card, home page
- Integration: full daily cycle, backup roundtrip
- Manual: notifications, ads, premium flow

---

## Code Style

- Async-first, type-hinted, Riverpod providers
- `@HiveType` models with `hive_ce_generator`
- Structured logging, custom exceptions
- No global state, dependency injection via Riverpod
- Material 3, light/dark auto, 48dp+ touch targets

---

## Boundaries

### Always Do
- Validate config on startup
- Log state transitions
- Notify on significant events
- Handle Ollama/parse failures gracefully (N/A — no API)
- Use date-seeded determinism

### Ask First
- Changing TP close percentages (N/A)
- Adding new notification channels
- Modifying deduplication logic (N/A)
- Increasing position size (N/A)

### Never Do
- Store API keys/secrets in git
- Use paid APIs or Firebase
- Banner/rewarded ads (interstitial only on exit)
- Subscriptions (one-time purchase only)
- Cloud sync or sign-in