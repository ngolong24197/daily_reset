import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers.dart';
import '../../core/constants/app_theme.dart';

class MorningPage extends ConsumerStatefulWidget {
  const MorningPage({super.key});

  @override
  ConsumerState<MorningPage> createState() => _MorningPageState();
}

class _MorningPageState extends ConsumerState<MorningPage> {
  bool _showMeaning = false;

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(contentProvider);
    final today = ref.watch(dateProvider);
    final progress = ref.watch(dailyProgressProvider);
    final isCompleted = progress.contains('morning');

    final quote = contentAsync.getQuoteForDate(today);
    final persistence = ref.read(persistenceProvider);
    final isFavorite = persistence.isQuoteFavorite(quote.id.toString());

    return Scaffold(
      appBar: AppBar(title: const Text('🌅 Morning Spark')),
      body: isCompleted
          ? _buildCompletedView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Semantics(
                    label: 'Daily quote by ${quote.author}',
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryAmber.withValues(alpha: 0.1), AppTheme.primaryOrange.withValues(alpha: 0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '"${quote.text}"',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '— ${quote.author}',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_showMeaning)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showMeaning = true),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('What does this mean?'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(quote.meaning, style: const TextStyle(fontSize: 16, height: 1.5)),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: () async {
                          final wasFavorite = persistence.isQuoteFavorite(quote.id.toString());
                          await persistence.toggleFavoriteQuote(quote.id.toString());
                          if (mounted) setState(() {});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(wasFavorite ? 'Removed from favorites' : 'Added to favorites!')),
                            );
                          }
                        },
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
                      ),
                      const SizedBox(width: 16),
                      IconButton.outlined(
                        onPressed: () => Share.share('"${quote.text}" — ${quote.author}'),
                        icon: const Icon(Icons.share),
                        tooltip: 'Share quote',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(dailyProgressProvider.notifier).markCompleted('morning');
                      ref.read(streakProvider.notifier).updateStreak(today);
                      setState(() {});
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Done'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppTheme.moodGreat),
            const SizedBox(height: 16),
            const Text('Morning Spark Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Come back tomorrow for a new quote.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}