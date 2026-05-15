import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/sound/sound_service.dart';

class BrainKickPage extends ConsumerStatefulWidget {
  const BrainKickPage({super.key});

  @override
  ConsumerState<BrainKickPage> createState() => _BrainKickPageState();
}

class _BrainKickPageState extends ConsumerState<BrainKickPage> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _quizComplete = false;

  @override
  Widget build(BuildContext context) {
    final content = ref.read(contentProvider);
    final today = ref.watch(dateProvider);
    final progress = ref.watch(dailyProgressProvider);
    final alreadyCompleted = progress.contains('brain');

    final questions = content.getTriviaForDate(today);
    // Mark trivia questions as seen when shown (idempotent — Set deduplicates)
    final questionIds = questions.map((q) => q.id).toList();
    content.markTriviaSeen(questionIds);
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('🧠 Brain Kick')),
        body: const Center(child: Text('No questions today. Check back tomorrow!')),
      );
    }

    if (_quizComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('🧠 Brain Kick')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 64, color: AppTheme.primaryAmber),
                const SizedBox(height: 16),
                Text('$_score/${questions.length} correct!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (!alreadyCompleted) ...[
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(soundServiceProvider).playChime(ChimeLength.short);
                      ref.read(dailyProgressProvider.notifier).markCompleted('brain');
                      ref.read(streakProvider.notifier).updateStreak(today);
                      setState(() {});
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save & Done'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _selectedAnswer = null;
                        _answered = false;
                        _score = 0;
                        _quizComplete = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Play Again'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _selectedAnswer = null;
                        _answered = false;
                        _score = 0;
                        _quizComplete = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Play Again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text('🧠 Question ${_currentIndex + 1} of ${questions.length}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ...List.generate(question.options.length, (i) => _AnswerButton(
              label: question.options[i],
              index: i,
              correctIndex: question.correctIndex,
              selectedAnswer: _selectedAnswer,
              answered: _answered,
              onTap: () => _selectAnswer(i),
            )),
            if (_answered) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.calmBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(question.explanation, style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (_currentIndex < questions.length - 1) {
                    setState(() {
                      _currentIndex++;
                      _selectedAnswer = null;
                      _answered = false;
                    });
                  } else {
                    setState(() => _quizComplete = true);
                  }
                },
                child: Text(_currentIndex < questions.length - 1 ? 'Next Question' : 'See Results'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final content = ref.read(contentProvider);
    final today = ref.read(dateProvider);
    final questions = content.getTriviaForDate(today);
    final question = questions[_currentIndex];
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == question.correctIndex) _score++;
    });
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final int index;
  final int correctIndex;
  final int? selectedAnswer;
  final bool answered;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.index,
    required this.correctIndex,
    required this.selectedAnswer,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? textColor;
    if (answered) {
      if (index == correctIndex) {
        bgColor = AppTheme.moodGreat;
        textColor = Colors.white;
      } else if (index == selectedAnswer) {
        bgColor = AppTheme.moodRough;
        textColor = Colors.white;
      } else {
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: 'Option ${String.fromCharCode(65 + index)}: $label',
        button: true,
        child: Material(
          color: bgColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: answered ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Text('${String.fromCharCode(65 + index)}.', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: TextStyle(color: textColor))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
