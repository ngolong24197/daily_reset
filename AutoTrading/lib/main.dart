import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/providers.dart';
import 'core/services/persistence/persistence_service.dart';
import 'core/services/content/content_service.dart';
import 'models/quote.dart';
import 'models/trivia.dart';
import 'core/services/ad/ad_service.dart';
import 'core/services/sound/sound_service.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/premium/premium_service.dart';
import 'features/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services (parallelized for faster startup)
  final persistence = PersistenceService();
  final content = ContentService();
  final adService = AdService();
  final soundService = SoundService();
  final notificationService = NotificationService();
  final premiumService = PremiumService(persistence);

  await Future.wait([
    persistence.init(),
    content.init(),
    adService.init(),
    soundService.init(),
    notificationService.init(),
    premiumService.init(),
  ]);

  // Load seen content IDs from persistence
  final seenQuoteIds = persistence.getSeenQuoteIds();
  final seenTriviaIds = persistence.getSeenTriviaIds();
  content.loadSeenIds(quoteIds: seenQuoteIds, triviaIds: seenTriviaIds);

  // Load cached remote content
  final cachedQuotes = persistence.getCachedRemoteQuotes();
  final cachedTrivia = persistence.getCachedRemoteTrivia();
  if (cachedQuotes != null) {
    content.loadRemoteContent(
      quotes: cachedQuotes.map((e) => Quote.fromJson(e)).toList(),
    );
  }
  if (cachedTrivia != null) {
    content.loadRemoteContent(
      trivia: cachedTrivia.map((e) => TriviaQuestion.fromJson(e)).toList(),
    );
  }

  // Wire seen-tracking callbacks so items are persisted when marked as seen
  content.onQuoteSeen = (id) async {
    await persistence.addSeenQuoteId(id);
  };
  content.onTriviaSeen = (ids) async {
    await persistence.addSeenTriviaIds(ids);
  };

  // Get initial data
  final today = DateTime.now();

  runApp(ProviderScope(
    overrides: [
      persistenceProvider.overrideWithValue(persistence),
      contentProvider.overrideWithValue(content),
      streakProvider.overrideWith((ref) => StreakNotifier(persistence)..updateStreak(today)),
      premiumProvider.overrideWith((ref) => PremiumNotifier(persistence)),
      dailyProgressProvider.overrideWith(
        (ref) => DailyProgressNotifier(persistence, today),
      ),
      adServiceProvider.overrideWithValue(adService),
      soundServiceProvider.overrideWithValue(soundService),
      notificationServiceProvider.overrideWithValue(notificationService),
      premiumServiceProvider.overrideWithValue(premiumService),
    ],
    child: const DailyResetApp(),
  ));
}

class DailyResetApp extends ConsumerWidget {
  const DailyResetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Daily Reset',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}