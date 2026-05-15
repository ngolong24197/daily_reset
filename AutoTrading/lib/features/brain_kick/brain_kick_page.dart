import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/sound/sound_service.dart';
import '../../models/trivia.dart';

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
  int _variant = 0;
  bool _quizComplete = false;
  bool _reviewingLastPlay = false;
  bool _isReplaying = false;
  List<int> _selectedAnswers = [];

  List<TriviaQuestion> get _questions {
    final content = ref.read(contentProvider);
    final today = ref.read(dateProvider);
    return content.getTriviaForDate(today, variant: _variant);
  }

  String get _todayStr {
    final today = ref.read(dateProvider);
    return '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(dateProvider);
    final progress = ref.watch(dailyProgressProvider);
    final alreadyCompleted = progress.contains('brain');

    if (_reviewingLastPlay) {
      return _buildReviewView();
    }

    final questions = _questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('🧠 Brain Kick')),
        body: const Center(child: Text('No questions today. Check back tomorrow!')),
      );
    }

    // Already completed today — offer View Last Play or Play Again
    // (skip if user is replaying via "Play Again")
    if (alreadyCompleted && !_quizComplete && !_isReplaying) {
      return Scaffold(
        appBar: AppBar(title: const Text('🧠 Brain Kick')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: AppTheme.moodGreat),
                const SizedBox(height: 16),
                const Text('Brain Kick Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Come back tomorrow for new questions.', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() {
                    _currentIndex = 0;
                    _reviewingLastPlay = true;
                  }),
                  icon: const Icon(Icons.history),
                  label: const Text('View Last Play'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _variant++;
                    _currentIndex = 0;
                    _selectedAnswer = null;
                    _answered = false;
                    _score = 0;
                    _quizComplete = false;
                    _isReplaying = true;
                    _selectedAnswers = [];
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play Again'),
                ),
              ],
            ),
          ),
        ),
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
                      final questionIds = questions.map((q) => q.id).toList();
                      ref.read(contentProvider).markTriviaSeen(questionIds);
                      setState(() {});
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save & Done'),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _variant++;
                    _currentIndex = 0;
                    _selectedAnswer = null;
                    _answered = false;
                    _score = 0;
                    _quizComplete = false;
                    _isReplaying = true;
                    _selectedAnswers = [];
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play Again'),
                ),
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
                    // Save quiz result every time a quiz finishes
                    final questionIds = questions.map((q) => q.id).toList();
                    ref.read(persistenceProvider).saveQuizResult(
                      _todayStr, questionIds, _selectedAnswers, _score,
                    );
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
    final question = _questions[_currentIndex];
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _selectedAnswers.add(index);
      if (index == question.correctIndex) _score++;
    });
  }

  Widget _buildReviewView() {
    final persistence = ref.read(persistenceProvider);
    final content = ref.read(contentProvider);
    final result = persistence.getQuizResult(_todayStr);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('🧠 Brain Kick')),
        body: const Center(child: Text('No quiz result found for today.')),
      );
    }

    final questionIds = List<int>.from(result['questionIds'] as List);
    final selectedAnswers = List<int>.from(result['selectedAnswers'] as List);

    final questions = <TriviaQuestion>[];
    for (final id in questionIds) {
      final q = content.getAllTrivia().where((t) => t.id == id).firstOrNull;
      if (q != null) questions.add(q);
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('🧠 Brain Kick')),
        body: const Center(child: Text('Could not load questions.')),
      );
    }

    final question = questions[_currentIndex];
    final userAnswer = _currentIndex < selectedAnswers.length ? selectedAnswers[_currentIndex] : -1;
    final isLast = _currentIndex >= questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('🧠 ${_currentIndex + 1} of ${questions.length}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ...List.generate(question.options.length, (i) {
              final isCorrect = i == question.correctIndex;
              final isUserChoice = i == userAnswer;
              Color bgColor;
              Color textColor;
              if (isCorrect) {
                bgColor = AppTheme.moodGreat;
                textColor = Colors.white;
              } else if (isUserChoice) {
                bgColor = AppTheme.moodRough;
                textColor = Colors.white;
              } else {
                bgColor = Colors.grey.shade200;
                textColor = Colors.grey;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Text('${String.fromCharCode(65 + i)}.', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(question.options[i], style: TextStyle(color: textColor))),
                        if (isCorrect) Icon(Icons.check_circle, color: textColor, size: 20),
                        if (isUserChoice && !isCorrect) Icon(Icons.cancel, color: textColor, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
                if (isLast) {
                  setState(() {
                    _reviewingLastPlay = false;
                    _currentIndex = 0;
                  });
                } else {
                  setState(() => _currentIndex++);
                }
              },
              child: Text(isLast ? 'Done' : 'Next'),
            ),
          ],
        ),
      ),
    );
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