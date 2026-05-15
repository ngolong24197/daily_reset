# Daily Reset — Task Checklist

## Phase 1: Foundation
- [ ] T0: Install Flutter SDK (3.16+ stable on Windows, PATH, flutter doctor)
- [ ] T1: Project scaffolding + pubspec + 50 quotes + 100 trivia + asset skeleton
- [ ] T2: Core models (Quote, Trivia, Streak, Mood) + Hive persistence + build_runner
- [ ] T3: ContentService + DateSeeder (deterministic daily content)
- [ ] **Checkpoint 1:** App builds, Hive inits, content deterministic

## Phase 2: App Shell + Home
- [ ] T4: Riverpod providers + MaterialApp shell + hub navigation
- [ ] T5: Home page (streak counter, 3 completion checkmarks, feature cards)
- [ ] **Checkpoint 2:** Navigable home with streak + cards

## Phase 3: Three Daily Interactions
- [ ] T6: Morning Spark (quote + meaning + save + share)
- [ ] T7: Brain Kick (1-3 trivia + answer feedback + explanations + score)
- [ ] T8: Daily Reflection (mood selector + journal + templated response)
- [ ] **Checkpoint 3:** Full daily cycle works end-to-end

## Phase 4: Streak + Notifications
- [ ] T9: Streak calendar heatmap + milestone badges (3/7/30) + chime sounds
- [ ] T10: Notification system (08:00 + 21:00 reminders, time pickers, reboot survive)
- [ ] **Checkpoint 4:** Calendar + milestones + sounds + notifications

## Phase 5: Monetization
- [ ] T11: Premium purchase ($2 one-time, in_app_purchase, restore)
- [ ] T12: Ad system (AdMob banner + interstitial on exit, premium skips)
- [ ] **Checkpoint 5:** Ads work, premium disables them, exit flow complete

## Phase 6: Polish + Advanced
- [ ] T13: Encrypted backup/restore (AES-256-GCM, PBKDF2, file_picker, premium-gated)
- [ ] T14: Home widget + accessibility + reduced motion + dark mode + final polish
- [ ] **Checkpoint 6:** Production-ready, full QA pass