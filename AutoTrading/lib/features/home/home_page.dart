import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants/app_theme.dart';
import '../morning/morning_page.dart';
import '../brain_kick/brain_kick_page.dart';
import '../reflection/reflection_page.dart';
import '../settings/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final streakData = ref.watch(streakProvider);
    final progress = ref.watch(dailyProgressProvider);
    final isPremium = ref.watch(premiumProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context, isPremium);
        if (shouldExit == true && context.mounted) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Reset'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _navigateTo(context, const SettingsPage()),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakCard(streak: streakData.currentStreak, bestStreak: streakData.bestStreak),
            const SizedBox(height: 16),
            _ProgressSection(progress: progress),
            const SizedBox(height: 24),
            _FeatureCard(
              icon: Icons.wb_sunny_rounded,
              title: 'Morning Spark',
              subtitle: 'Start your day with inspiration',
              color: AppTheme.primaryAmber,
              isCompleted: progress.contains('morning'),
              onTap: () => _navigateTo(context, const MorningPage()),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.psychology_rounded,
              title: 'Brain Kick',
              subtitle: 'Challenge your mind',
              color: AppTheme.calmBlue,
              isCompleted: progress.contains('brain'),
              onTap: () => _navigateTo(context, const BrainKickPage()),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.nightlight_rounded,
              title: 'Daily Reflection',
              subtitle: 'Check in with yourself',
              color: AppTheme.reflectionBlue,
              isCompleted: progress.contains('reflection'),
              onTap: () => _navigateTo(context, const ReflectionPage()),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context, bool isPremium) async {
    if (isPremium) {
      return true;
    }
    // Show "See you tomorrow" dialog, then ad, then exit
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('See you tomorrow 👋'),
        content: const Text('Great job today! Come back tomorrow for new content.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      // Show ad as side-effect. PopScope handler will exit after this returns.
      final adService = ref.read(adServiceProvider);
      adService.showInterstitial(() {
        // Ad dismissed — nothing to do here, PopScope already handles exit.
      });
    }
    return result;
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;

  const _StreakCard({required this.streak, required this.bestStreak});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak >= 7
                ? [AppTheme.primaryOrange, AppTheme.primaryAmber]
                : [AppTheme.primaryAmber, AppTheme.primaryAmber.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              streak >= 7 ? Icons.local_fire_department : Icons.whatshot_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak day${streak == 1 ? '' : 's'} streak',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Best: $bestStreak days',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Set<String> progress;

  const _ProgressSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ProgressDot(icon: Icons.wb_sunny_rounded, label: 'Spark', done: progress.contains('morning')),
        _ProgressDot(icon: Icons.psychology_rounded, label: 'Brain', done: progress.contains('brain')),
        _ProgressDot(icon: Icons.nightlight_rounded, label: 'Reflect', done: progress.contains('reflection')),
      ],
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;

  const _ProgressDot({required this.icon, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: done ? AppTheme.moodGreat : Colors.grey.shade300,
          child: Icon(icon, color: done ? Colors.white : Colors.grey, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: done ? AppTheme.moodGreat : Colors.grey)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isCompleted;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: AppTheme.moodGreat, size: 28)
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}