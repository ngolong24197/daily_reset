import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reset/models/streak.dart';
import 'package:daily_reset/models/mood.dart';
import 'package:daily_reset/models/quote.dart';
import 'package:daily_reset/models/trivia.dart';

void main() {
  group('StreakData', () {
    test('default constructor has zero values', () {
      final streak = StreakData();
      expect(streak.currentStreak, 0);
      expect(streak.bestStreak, 0);
      expect(streak.lastActiveDate, '');
      expect(streak.completedDates, isEmpty);
      expect(streak.milestones, isEmpty);
    });

    test('toJson and fromJson roundtrip', () {
      final original = StreakData(
        currentStreak: 7,
        bestStreak: 14,
        lastActiveDate: '2024-04-17',
        completedDates: ['2024-04-16', '2024-04-17'],
        milestones: {'3': true, '7': true},
      );

      final json = original.toJson();
      final restored = StreakData.fromJson(json);

      expect(restored.currentStreak, 7);
      expect(restored.bestStreak, 14);
      expect(restored.lastActiveDate, '2024-04-17');
      expect(restored.completedDates, ['2024-04-16', '2024-04-17']);
      expect(restored.milestones['3'], true);
      expect(restored.milestones['7'], true);
    });

    test('fromJson handles missing fields with defaults', () {
      final restored = StreakData.fromJson({});
      expect(restored.currentStreak, 0);
      expect(restored.bestStreak, 0);
      expect(restored.lastActiveDate, '');
      expect(restored.completedDates, isEmpty);
      expect(restored.milestones, isEmpty);
    });
  });

  group('MoodEntry', () {
    test('toJson and fromJson roundtrip', () {
      final now = DateTime(2024, 4, 17, 10, 30);
      final entry = MoodEntry(
        id: 'test-id',
        date: '2024-04-17',
        mood: Mood.great,
        journalText: 'Had a wonderful day!',
        createdAt: now,
      );

      final json = entry.toJson();
      final restored = MoodEntry.fromJson(json);

      expect(restored.id, 'test-id');
      expect(restored.date, '2024-04-17');
      expect(restored.mood, Mood.great);
      expect(restored.journalText, 'Had a wonderful day!');
      expect(restored.createdAt, now);
    });

    test('all moods can be serialized and deserialized', () {
      for (final mood in Mood.values) {
        final entry = MoodEntry(
          id: 'test-${mood.index}',
          date: '2024-04-17',
          mood: mood,
          journalText: '',
          createdAt: DateTime(2024, 4, 17),
        );

        final json = entry.toJson();
        final restored = MoodEntry.fromJson(json);

        expect(restored.mood, mood);
      }
    });

    test('Mood enum has expected values', () {
      expect(Mood.values.length, 5);
      expect(Mood.values, contains(Mood.great));
      expect(Mood.values, contains(Mood.good));
      expect(Mood.values, contains(Mood.okay));
      expect(Mood.values, contains(Mood.low));
      expect(Mood.values, contains(Mood.rough));
    });
  });

  group('Quote', () {
    test('fromJson creates valid Quote', () {
      final json = {
        'id': 1,
        'text': 'Test quote',
        'author': 'Test Author',
        'meaning': 'Test meaning',
      };

      final quote = Quote.fromJson(json);
      expect(quote.id, 1);
      expect(quote.text, 'Test quote');
      expect(quote.author, 'Test Author');
      expect(quote.meaning, 'Test meaning');
    });
  });

  group('TriviaQuestion', () {
    test('fromJson creates valid TriviaQuestion', () {
      final json = {
        'id': 1,
        'question': 'What is 2+2?',
        'options': ['3', '4', '5', '6'],
        'correctIndex': 1,
        'explanation': '2+2 equals 4.',
        'category': 'science',
      };

      final trivia = TriviaQuestion.fromJson(json);
      expect(trivia.id, 1);
      expect(trivia.question, 'What is 2+2?');
      expect(trivia.options.length, 4);
      expect(trivia.options[1], '4');
      expect(trivia.correctIndex, 1);
      expect(trivia.explanation, '2+2 equals 4.');
      expect(trivia.category, 'science');
    });
  });
}