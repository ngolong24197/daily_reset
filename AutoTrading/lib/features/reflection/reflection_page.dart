import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers.dart';
import '../../core/constants/app_theme.dart';
import '../../models/mood.dart';
import '../../widgets/mood_selector.dart';

class ReflectionPage extends ConsumerStatefulWidget {
  const ReflectionPage({super.key});

  @override
  ConsumerState<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends ConsumerState<ReflectionPage> {
  Mood? _selectedMood;
  final _journalController = TextEditingController();
  String? _response;
  static const _uuid = Uuid();

  static const Map<Mood, List<String>> _dailyResponseTemplates = {
    Mood.great: [
      "That's wonderful! Keep carrying that energy forward into tomorrow.",
      "Great days like these are worth remembering. What made it special?",
      "Your positivity is contagious! Keep nurturing what made you smile.",
    ],
    Mood.good: [
      "A good day is something to appreciate. You're doing well.",
      "Steady progress is still progress. Keep it up!",
      "Good days add up. You're building something great.",
    ],
    Mood.okay: [
      "Okay days are perfectly normal. Not every day needs to be extraordinary.",
      "You showed up, and that counts. Tomorrow is a fresh start.",
      "Even on okay days, you're still moving forward. That matters.",
    ],
    Mood.low: [
      "It takes courage to acknowledge a tough day. Rest up and be kind to yourself.",
      "Tough days build resilience. Tomorrow is a new beginning.",
      "Some days are just about getting through. You did that. Be proud.",
    ],
    Mood.rough: [
      "I'm sorry today was rough. Tomorrow is a completely fresh start.",
      "Rough days don't define you. Take it easy tonight and start fresh tomorrow.",
      "You survived a hard day. That takes strength. Rest well.",
    ],
  };

  static const Map<Mood, List<String>> _weeklyResponseTemplates = {
    Mood.great: [
      "What an incredible week! What were the highlights?",
      "This sounds like a week worth remembering. What made it special?",
      "Your energy this week was amazing! What contributed most to that?",
    ],
    Mood.good: [
      "A solid week overall. What went particularly well?",
      "Good weeks are built one day at a time. You're doing it!",
      "It's great when the good days outweigh the tough ones. Well done!",
    ],
    Mood.okay: [
      "An okay week is perfectly fine. Not every week needs to be extraordinary.",
      "Some rest, some good moments — that's a real week. Rest up for next week!",
      "Even okay weeks have value. What did you learn?",
    ],
    Mood.low: [
      "It sounds like this week had its challenges. What helped you through?",
      "Tough weeks build character. Take what lessons you can and rest.",
      "Some weeks are just about surviving. Be proud you made it through.",
    ],
    Mood.rough: [
      "I'm sorry this week was rough. It takes strength to keep going.",
      "Rough weeks feel endless, but they do end. Rest and reset.",
      "You made it through a hard week. That resilience will serve you well.",
    ],
  };

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(dateProvider);
    final isWeekend = today.weekday == DateTime.saturday || today.weekday == DateTime.sunday;
    final progress = ref.watch(dailyProgressProvider);
    final isCompleted = progress.contains('reflection');
    final persistence = ref.read(persistenceProvider);
    final todayStr = _formatDate(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = _formatDate(yesterday);

    // Get recent reflections
    final todayEntry = persistence.getMoodEntry(todayStr);
    final yesterdayEntry = persistence.getMoodEntry(yesterdayStr);

    if (isCompleted || todayEntry != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('🌙 Daily Reflection')),
        body: _ReflectionHistory(
          todayEntry: todayEntry,
          yesterdayEntry: yesterdayEntry,
          isWeekend: isWeekend,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🌙 Daily Reflection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isWeekend ? 'How was your week?' : 'How are you feeling today?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) => setState(() => _selectedMood = mood),
            ),
            if (_selectedMood != null) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _journalController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: isWeekend ? 'What made this week memorable? (optional)' : 'Want to add a short note? (optional)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_response != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.reflectionBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.reflectionBlue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: AppTheme.reflectionBlue),
                          SizedBox(width: 8),
                          Text('Daily Reset', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.reflectionBlue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_response!, style: const TextStyle(fontSize: 16, height: 1.5)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveReflection,
                icon: const Icon(Icons.check),
                label: const Text('Save Reflection'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveReflection() async {
    if (_selectedMood == null) return;

    final today = ref.read(dateProvider);
    final todayStr = _formatDate(today);

    final entry = MoodEntry(
      id: _uuid.v4(),
      date: todayStr,
      mood: _selectedMood!,
      journalText: _journalController.text,
      createdAt: DateTime.now(),
    );

    await ref.read(persistenceProvider).saveMoodEntry(entry);
    await ref.read(dailyProgressProvider.notifier).markCompleted('reflection');
    ref.read(streakProvider.notifier).updateStreak(today);

    // Show templated response
    final isWeekend = today.weekday == DateTime.saturday || today.weekday == DateTime.sunday;
    final templates = isWeekend ? _weeklyResponseTemplates[_selectedMood!]! : _dailyResponseTemplates[_selectedMood!]!;
    final dayIndex = today.day % templates.length;
    setState(() => _response = templates[dayIndex]);
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ReflectionHistory extends StatelessWidget {
  final MoodEntry? todayEntry;
  final MoodEntry? yesterdayEntry;
  final bool isWeekend;

  const _ReflectionHistory({
    this.todayEntry,
    this.yesterdayEntry,
    required this.isWeekend,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (todayEntry != null) ...[
            const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ReflectionCard(entry: todayEntry!),
            const SizedBox(height: 24),
          ],
          if (yesterdayEntry != null) ...[
            const Text('Yesterday', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ReflectionCard(entry: yesterdayEntry!),
          ],
          if (todayEntry == null && yesterdayEntry == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No reflections yet. Start your first one!'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final MoodEntry entry;

  const _ReflectionCard({required this.entry});

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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_moodIcon, color: _moodColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  _moodLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _moodColor,
                  ),
                ),
              ],
            ),
            if (entry.journalText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.journalText,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
