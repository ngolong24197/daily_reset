import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers.dart';
import '../../core/constants/app_theme.dart';
import '../../models/quote.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persistence = ref.read(persistenceProvider);
    final content = ref.read(contentProvider);
    final isPremium = ref.watch(premiumProvider);
    final favoriteIds = persistence.getFavoriteQuotes();

    final favoriteQuotes = <Quote>[];
    for (final idStr in favoriteIds) {
      final q = content.getQuoteById(int.tryParse(idStr) ?? -1);
      if (q != null) favoriteQuotes.add(q);
    }

    final maxFree = 10;
    final isAtLimit = !isPremium && favoriteQuotes.length >= maxFree;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Quotes')),
      body: favoriteQuotes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No favorites yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Tap the heart icon on any quote to save it here.', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (!isPremium)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      isAtLimit
                          ? 'Free limit reached ($maxFree). Upgrade to Premium for unlimited.'
                          : '${favoriteQuotes.length}/$maxFree favorites (Premium = unlimited)',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favoriteQuotes.length,
                    itemBuilder: (context, index) {
                      final quote = favoriteQuotes[index];
                      return _FavoriteQuoteCard(
                        quote: quote,
                        onRemove: () async {
                          await persistence.toggleFavoriteQuote(quote.id.toString());
                          ref.invalidate(premiumProvider); // trigger rebuild
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from favorites')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FavoriteQuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onRemove;

  const _FavoriteQuoteCard({required this.quote, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${quote.text}"',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              '— ${quote.author}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.outlined(
                  onPressed: () => Share.share('"${quote.text}" — ${quote.author}'),
                  icon: const Icon(Icons.share, size: 20),
                  tooltip: 'Share',
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: onRemove,
                  icon: const Icon(Icons.favorite, size: 20, color: AppTheme.moodRough),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}