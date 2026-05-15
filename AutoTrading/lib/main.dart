import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

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

/// Call this to force a full app restart (clears all state, re-reads from disk).
void restartApp() {
  _restartKey.value++;
}

final ValueNotifier<int> _restartKey = ValueNotifier(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

  // Set install-specific seed so content varies across reinstalls
  content.setInstallSeed(persistence.installSeed);

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

  runApp(_AppRestarter(
    persistence: persistence,
    content: content,
    adService: adService,
    soundService: soundService,
    notificationService: notificationService,
    premiumService: premiumService,
    today: today,
  ));
}

class _AppRestarter extends StatefulWidget {
  final PersistenceService persistence;
  final ContentService content;
  final AdService adService;
  final SoundService soundService;
  final NotificationService notificationService;
  final PremiumService premiumService;
  final DateTime today;

  const _AppRestarter({
    required this.persistence,
    required this.content,
    required this.adService,
    required this.soundService,
    required this.notificationService,
    required this.premiumService,
    required this.today,
  });

  @override
  State<_AppRestarter> createState() => _AppRestarterState();
}

class _AppRestarterState extends State<_AppRestarter> {
  int _key = 0;

  @override
  void initState() {
    super.initState();
    _restartKey.addListener(_onRestart);
  }

  @override
  void dispose() {
    _restartKey.removeListener(_onRestart);
    super.dispose();
  }

  void _onRestart() {
    setState(() => _key++);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(_key),
      overrides: [
        persistenceProvider.overrideWithValue(widget.persistence),
        contentProvider.overrideWithValue(widget.content),
        streakProvider.overrideWith((ref) => StreakNotifier(widget.persistence)..updateStreak(widget.today)),
        premiumProvider.overrideWith((ref) => PremiumNotifier(widget.persistence)),
        dailyProgressProvider.overrideWith(
          (ref) => DailyProgressNotifier(widget.persistence, widget.today),
        ),
        adServiceProvider.overrideWithValue(widget.adService),
        soundServiceProvider.overrideWithValue(widget.soundService),
        notificationServiceProvider.overrideWithValue(widget.notificationService),
        premiumServiceProvider.overrideWithValue(widget.premiumService),
      ],
      child: const DailyResetApp(),
    );
  }
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