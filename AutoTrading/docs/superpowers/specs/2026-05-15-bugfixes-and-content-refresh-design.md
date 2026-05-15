# Design: Bug Fixes & Content Refresh Strategy

**Date:** 2026-05-15
**Status:** Approved
**Scope:** 6 bug fixes + content expansion & refresh system

---

## Overview

Fix 6 identified issues in the Daily Reset app and add a content refresh system that expands the bundled content library from 50/100 to 300+/300+ (quotes/trivia), tracks seen items, and allows premium users to fetch new content from a remote cloud storage URL.

---

## Bug Fixes

### BF-1: SoundService — Wire Chime Sounds

**Problem:** `SoundService` is initialized but never called. No sounds play anywhere.

**Fix:**
- Play `chime_short` on feature completion (morning/brain/reflection "Mark as Done")
- Play `chime_medium` on streak milestone hit (3, 7, 30 days)
- Play `chime_long` on premium activation
- All calls wrapped in try/catch (already resilient to silent mode)

**Files:** `morning_page.dart`, `brain_kick_page.dart`, `reflection_page.dart`, `home_page.dart`, `premium_page.dart`

### BF-2: Streak Milestones — Wire checkMilestone() into UI

**Problem:** `StreakNotifier.checkMilestone()` exists but is never called.

**Fix:**
- Call `checkMilestone()` inside `StreakNotifier.updateStreak()` after streak increment
- Add a `milestoneReachedProvider` (StateProvider<int?>, null = no milestone) that emits the milestone number
- Home page listens and shows a congratulatory dialog with fire animation (Lottie `streak_fire.json`)
- Dialog dismisses and milestone is marked as seen

**Files:** `providers.dart`, `home_page.dart`

### BF-3: Delete Unused quote_card.dart

**Problem:** `widgets/quote_card.dart` exists but morning page builds its own quote display inline.

**Fix:** Delete the file. No other file imports it.

**Files:** Delete `lib/widgets/quote_card.dart`

### BF-4: Reflection Page DateTime.now() Inconsistency

**Problem:** `reflection_page.dart` uses `DateTime.now()` directly (lines 79, 98) instead of the injected `dateProvider`.

**Fix:** Replace `DateTime.now()` with `ref.watch(dateProvider)` for consistency.

**Files:** `reflection_page.dart`

### BF-5: NotificationService Re-instantiated on Every Toggle

**Problem:** `settings_page.dart` creates `NotificationService()` fresh on every switch toggle.

**Fix:**
- Add `notificationServiceProvider` to `providers.dart`
- Override in `main()` like other services
- Settings page reads `ref.read(notificationServiceProvider)` instead of constructing new instances

**Files:** `providers.dart`, `settings_page.dart`, `main.dart`

### BF-6: Premium Purchase Stub — Wire In-App Purchase

**Problem:** `PremiumPage._purchase()` directly sets premium to `true` with no store verification.

**Fix:**
- `PremiumService` wraps `in_app_purchase` package (already in pubspec)
- Listens to purchase stream, verifies completion, updates premium state
- Keep a debug override for testing (gated by `kDebugMode`)
- Real SKU placeholder: `daily_reset_premium` (replaced at ship time)
- Restore purchases reads from store stream

**Files:** `premium_service.dart`, `premium_page.dart`

---

## Content Refresh Strategy

### CR-1: Expand Bundled Content

**Current:** 50 quotes, 100 trivia questions
**Target:** 300+ quotes, 300+ trivia questions

The bundled JSON files in `assets/data/` need to be expanded. New trivia items continue using existing categories (science, history, geography, pop_culture) and can add new categories. Quote IDs continue from current range. Trivia IDs continue from current range.

### CR-2: Seen-Content Tracking

**Storage:** New Hive box `seenContent` with:
- `seen_quote_ids`: List<int> — quote IDs that have been shown
- `seen_trivia_ids`: List<int> — trivia question IDs that have been shown

**Selection algorithm (in ContentService):**
1. Get all items from pool (bundled + remote)
2. Separate into `unseen` and `seen` lists
3. If `unseen` is non-empty: shuffle `unseen` with date-seeded Random, pick first
4. If all items are seen: fall back to pure date-seeded selection (current behavior)
5. When an item is shown, add its ID to the seen list and persist

**80% threshold:**
- `ContentService` exposes `bool get needsQuoteRefresh` and `bool get needsTriviaRefresh`
- Computed as: `seenIds.length / totalPoolSize >= 0.8`
- UI reads these to show refresh hints

### CR-3: Remote Content Refresh (Premium-Only)

**Access:** Settings page shows "Refresh Content" row with premium lock icon. Premium users can tap it.

**Flow:**
1. User taps "Refresh Content"
2. App fetches `quotes.json` and `trivia.json` from configurable cloud storage URLs
3. Response is parsed and validated (must be List with expected fields)
4. New items are merged into local pool (deduped by ID)
5. Fetched content is cached in Hive box `remoteContent` (keys: `quotes`, `trivia`)
6. Seen-tracking treats all new items as unseen
7. Success/failure snackbar shown
8. On next app launch, cached remote content is loaded alongside bundled content

**URLs stored as constants in a config file, easy to swap:**
```dart
class ContentUrls {
  static const String quotes = 'https://[cloud-storage-url]/quotes.json';
  static const String trivia = 'https://[cloud-storage-url]/trivia.json';
}
```

**Error handling:**
- Network failure → snackbar "Could not reach server. Try again later."
- Invalid JSON → snackbar "Content update failed. Try again later."
- Partial success (quotes ok, trivia fail) → save what worked, report partial success

**Offline behavior:**
- App works fully offline with bundled baseline
- Previously fetched remote content is cached in Hive and available offline
- Only the fetch action requires network

### CR-4: Content File Format (Remote)

Same format as bundled files. IDs must be unique across bundled + remote:
- Bundled quotes: IDs 1-300
- Remote quotes: IDs 301+
- Bundled trivia: IDs 1-300
- Remote trivia: IDs 301+

```json
// quotes.json
[
  {"id": 301, "text": "...", "author": "...", "meaning": "..."}
]

// trivia.json
[
  {"id": 301, "question": "...", "options": ["A","B","C","D"], "correctIndex": 0, "explanation": "...", "category": "science"}
]
```

### CR-5: ContentService Refactor

`ContentService` needs to:
1. Load bundled content on init (existing)
2. Load cached remote content from Hive on init
3. Merge both into a unified pool (dedup by ID)
4. Use seen-content tracking for selection
5. Expose `needsQuoteRefresh` / `needsTriviaRefresh` flags
6. Expose `Future<bool> refreshFromRemote()` method for the fetch action

**New dependencies:**
- `http` package for remote content fetch
- Hive box `remoteContent` and `seenContent`

---

## Implementation Order

1. BF-3: Delete quote_card.dart (simplest, removes dead code)
2. BF-4: Fix DateTime.now() in reflection (one-liner)
3. BF-5: NotificationService provider injection
4. BF-1: Wire SoundService chimes
5. BF-2: Wire streak milestones
6. BF-6: Premium IAP integration
7. CR-1: Expand bundled content (300+ quotes, 300+ trivia)
8. CR-2: Seen-content tracking in ContentService
9. CR-3: Remote content refresh (premium-gated)
10. CR-4: Content URL config
11. CR-5: ContentService refactor to merge bundled + remote

Items 1-5 are independent bug fixes. Items 7-11 form the content refresh feature and should be done sequentially.