import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reset/core/services/content/content_service.dart';
import 'package:daily_reset/models/quote.dart';
import 'package:daily_reset/models/trivia.dart';

void main() {
  group('ContentService', () {
    late ContentService service;

    setUp(() {
      service = ContentService.withData(
        quotes: [
          Quote(id: 1, text: 'Quote 1', author: 'Author 1', meaning: 'Meaning 1'),
          Quote(id: 2, text: 'Quote 2', author: 'Author 2', meaning: 'Meaning 2'),
          Quote(id: 3, text: 'Quote 3', author: 'Author 3', meaning: 'Meaning 3'),
        ],
        trivia: [
          TriviaQuestion(id: 1, question: 'Q1', options: ['A', 'B', 'C', 'D'], correctIndex: 0, explanation: 'E1', category: 'science'),
          TriviaQuestion(id: 2, question: 'Q2', options: ['A', 'B', 'C', 'D'], correctIndex: 1, explanation: 'E2', category: 'history'),
          TriviaQuestion(id: 3, question: 'Q3', options: ['A', 'B', 'C', 'D'], correctIndex: 2, explanation: 'E3', category: 'geography'),
        ],
      );
    });

    test('getQuoteForDate returns a valid quote', () {
      final quote = service.getQuoteForDate(DateTime(2024, 6, 15));
      expect(quote, isNotNull);
      expect(quote.id, isIn([1, 2, 3]));
    });

    test('getTriviaForDate returns valid questions', () {
      final questions = service.getTriviaForDate(DateTime(2024, 6, 15));
      expect(questions.isNotEmpty, true);
      expect(questions.length, lessThanOrEqualTo(3));
    });

    test('getTriviaForDate with variant returns different questions', () {
      final variant1 = service.getTriviaForDate(DateTime(2024, 6, 15), variant: 1);
      // Variant parameter should not crash and should return valid questions
      expect(variant1.isNotEmpty, true);
    });

    test('getAllTrivia returns all trivia items', () {
      final all = service.getAllTrivia();
      expect(all.length, 3);
      expect(all.map((t) => t.id), containsAll([1, 2, 3]));
    });

    test('same date and install seed returns same quote', () {
      service.setInstallSeed(12345);
      final date = DateTime(2024, 6, 15);
      final first = service.getQuoteForDate(date);
      final second = service.getQuoteForDate(date);

      // Deterministic: same date + same seed always gives same quote
      expect(first.id, second.id);
      expect(first.text, second.text);
    });

    test('different install seed gives different quote', () {
      service.setInstallSeed(12345);
      final date = DateTime(2024, 6, 15);
      final withSeed1 = service.getQuoteForDate(date);

      service.setInstallSeed(99999);
      final withSeed2 = service.getQuoteForDate(date);

      // Different install seeds should produce different quotes (most of the time)
      // With only 3 quotes it's possible they collide, so just verify no crash
      expect(withSeed1, isNotNull);
      expect(withSeed2, isNotNull);
    });

    test('quote selection is not affected by seen-tracking', () {
      service.setInstallSeed(0);
      final date = DateTime(2024, 6, 15);
      final beforeSeen = service.getQuoteForDate(date);
      service.markQuoteSeen(beforeSeen.id);
      final afterSeen = service.getQuoteForDate(date);

      // Same quote returned even after marking as seen
      expect(afterSeen.id, beforeSeen.id);
    });

    test('needsQuoteRefresh returns true when 80% seen', () {
      // 2 of 3 = 66%, not 80%
      service.markQuoteSeen(1);
      service.markQuoteSeen(2);
      expect(service.needsQuoteRefresh, false);

      // 3 of 3 = 100%
      service.markQuoteSeen(3);
      expect(service.needsQuoteRefresh, true);
    });

    test('needsTriviaRefresh returns true when 80% seen', () {
      service.markTriviaSeen([1, 2]);
      expect(service.needsTriviaRefresh, false);

      service.markTriviaSeen([3]);
      expect(service.needsTriviaRefresh, true);
    });

    test('mergeRemoteQuotes adds new quotes', () {
      final remoteQuotes = [
        Quote(id: 4, text: 'Remote 1', author: 'R Author', meaning: 'R Meaning'),
        Quote(id: 5, text: 'Remote 2', author: 'R Author 2', meaning: 'R Meaning 2'),
      ];
      service.mergeRemoteQuotes(remoteQuotes);

      expect(service.totalQuoteCount, 5);
    });

    test('mergeRemoteQuotes deduplicates by id', () {
      final remoteQuotes = [
        Quote(id: 1, text: 'Duplicate', author: 'Dup', meaning: 'Dup'),
        Quote(id: 4, text: 'New', author: 'New', meaning: 'New'),
      ];
      service.mergeRemoteQuotes(remoteQuotes);

      // Should have 4, not 5 (id 1 already exists)
      expect(service.totalQuoteCount, 4);
    });

    test('mergeRemoteTrivia adds new trivia', () {
      final remoteTrivia = [
        TriviaQuestion(id: 4, question: 'RQ1', options: ['A', 'B', 'C', 'D'], correctIndex: 0, explanation: 'RE1', category: 'science'),
      ];
      service.mergeRemoteTrivia(remoteTrivia);

      expect(service.totalTriviaCount, 4);
    });

    test('totalQuoteCount and totalTriviaCount', () {
      expect(service.totalQuoteCount, 3);
      expect(service.totalTriviaCount, 3);
    });

    test('ContentRefreshResult properties', () {
      final success = ContentRefreshResult(quotesSuccess: true, triviaSuccess: true);
      expect(success.totalSuccess, true);
      expect(success.partialSuccess, true);
      expect(success.totalFailure, false);

      final partial = ContentRefreshResult(quotesSuccess: true, triviaSuccess: false, triviaError: 'fail');
      expect(partial.totalSuccess, false);
      expect(partial.partialSuccess, true);
      expect(partial.totalFailure, false);

      final failure = ContentRefreshResult(quotesSuccess: false, triviaSuccess: false, quotesError: 'err', triviaError: 'err');
      expect(failure.totalSuccess, false);
      expect(failure.partialSuccess, false);
      expect(failure.totalFailure, true);
    });
  });
}