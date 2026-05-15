import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants/app_theme.dart';
import '../../models/mood.dart';

class ReflectionHistoryPage extends ConsumerWidget {
  const ReflectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persistence = ref.read(persistenceProvider);
    final allEntries = persistence.moodBox.keys
        .map((key) {
          final data = persistence.moodBox.get(key);
          if (data == null) return null;
          return MoodEntry.fromJson(Map<String, dynamic>.from(data as Map));
        })
        .whereType<MoodEntry>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Reflection History')),
      body: allEntries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No reflections yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Complete a Daily Reflection to start building history.', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allEntries.length,
              itemBuilder: (context, index) {
                final entry = allEntries[index];
                return _ReflectionHistoryCard(entry: entry);
              },
            ),
    );
  }
}

class _ReflectionHistoryCard extends StatelessWidget {
  final MoodEntry entry;

  const _ReflectionHistoryCard({required this.entry});

  IconData get _moodIcon {
    switch (entry.mood) {
      case Mood.great:
        return Icons.sentiment_very_satisfied;
      case Mood.good:
        return Icons.sentiment_satisfied;
      case Mood.okay:
        return Icons.sentiment_neutral;
      case Mood.low:
        return Icons.sentiment_dissatisfied;
      case Mood.rough:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Color get _moodColor {
    switch (entry.mood) {
      case Mood.great:
        return AppTheme.moodGreat;
      case Mood.good:
        return AppTheme.moodGood;
      case Mood.okay:
        return AppTheme.moodOkay;
      case Mood.low:
        return AppTheme.moodLow;
      case Mood.rough:
        return AppTheme.moodRough;
    }
  }

  String get _moodLabel {
    switch (entry.mood) {
      case Mood.great:
        return 'Great';
      case Mood.good:
        return 'Good';
      case Mood.okay:
        return 'Okay';
      case Mood.low:
        return 'Low';
      case Mood.rough:
        return 'Rough';
    }
  }

  String get _formattedDate {
    final parts = entry.date.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_moodIcon, color: _moodColor, size: 28),
                const SizedBox(width: 12),
                Text(_moodLabel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _moodColor)),
                const Spacer(),
                Text(_formattedDate, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
            if (entry.journalText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(entry.journalText, style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}