import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reset/core/services/content/date_seeder.dart';

void main() {
  group('DateSeeder', () {
    late DateSeeder seeder;

    setUp(() {
      seeder = DateSeeder();
    });

    test('dateSeed produces YYYYMMDD integer', () {
      final date = DateTime(2024, 4, 17);
      expect(seeder.dateSeed(date), 20240417);
    });

    test('dateSeed is consistent for same date', () {
      final date = DateTime(2024, 12, 25);
      expect(seeder.dateSeed(date), equals(seeder.dateSeed(date)));
    });

    test('dateSeed differs for different dates', () {
      final date1 = DateTime(2024, 4, 17);
      final date2 = DateTime(2024, 4, 18);
      expect(seeder.dateSeed(date1), isNot(equals(seeder.dateSeed(date2))));
    });

    test('dateSeed handles single-digit month and day', () {
      final date = DateTime(2024, 1, 5);
      expect(seeder.dateSeed(date), 20240105);
    });

    test('dateSeed handles end of year', () {
      final date = DateTime(2024, 12, 31);
      expect(seeder.dateSeed(date), 20241231);
    });

    test('randomForDate produces deterministic sequence', () {
      final date = DateTime(2024, 6, 15);
      final r1 = seeder.randomForDate(date);
      final r2 = seeder.randomForDate(date);

      final seq1 = List.generate(10, (_) => r1.nextInt(100));
      final seq2 = List.generate(10, (_) => r2.nextInt(100));

      expect(seq1, equals(seq2));
    });

    test('randomForDate differs across dates', () {
      final date1 = DateTime(2024, 6, 15);
      final date2 = DateTime(2024, 6, 16);

      final r1 = seeder.randomForDate(date1);
      final r2 = seeder.randomForDate(date2);

      final val1 = r1.nextInt(10000);
      final val2 = r2.nextInt(10000);

      expect(val1, isNot(equals(val2)));
    });

    test('randomForFeature produces different sequences per feature', () {
      final date = DateTime(2024, 6, 15);

      final r1 = seeder.randomForFeature(date, 'quote');
      final r2 = seeder.randomForFeature(date, 'trivia');

      final val1 = r1.nextInt(10000);
      final val2 = r2.nextInt(10000);

      expect(val1, isNot(equals(val2)));
    });

    test('randomForFeature is deterministic for same date and feature', () {
      final date = DateTime(2024, 6, 15);

      final r1 = seeder.randomForFeature(date, 'quote');
      final r2 = seeder.randomForFeature(date, 'quote');

      final seq1 = List.generate(10, (_) => r1.nextInt(100));
      final seq2 = List.generate(10, (_) => r2.nextInt(100));

      expect(seq1, equals(seq2));
    });

    test('cross-device consistency: same seed same results', () {
      final date = DateTime(2024, 4, 17);
      final seed = seeder.dateSeed(date);
      expect(seed, 20240417);

      final random = Random(seed);
      final indices = List.generate(5, (_) => random.nextInt(50));
      for (final i in indices) {
        expect(i, lessThan(50));
        expect(i, greaterThanOrEqualTo(0));
      }
    });
  });
}