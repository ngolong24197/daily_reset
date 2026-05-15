import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/providers.dart';
import 'core/services/persistence/persistence_service.dart';
import 'core/services/content/content_service.dart';
import 'core/services/ad/ad_service.dart';
import 'core/services/sound/sound_service.dart';
import 'core/services/premium/premium_service.dart';
import 'features/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services (parallelized for faster startup)
  final persistence = PersistenceService();
  final content = ContentService();
  final adService = AdService();
  final soundService = SoundService();
  final premiumService = PremiumService(persistence);

  await Future.wait([
    persistence.init(),
    content.init(),
    adService.init(),
    soundService.init(),
    premiumService.init(),
  ]);

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