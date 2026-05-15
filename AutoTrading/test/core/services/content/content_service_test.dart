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

    test('seen quotes are deprioritized', () {
      service.markQuoteSeen(1);
      service.markQuoteSeen(2);

      // With only 1 unseen quote, it should always be selected
      for (int day = 1; day <= 10; day++) {
        final quote = service.getQuoteForDate(DateTime(2024, 6, day));
        expect(quote.id, 3);
      }
    });

    test('all seen quotes fall back to date-seeded selection', () {
      service.markQuoteSeen(1);
      service.markQuoteSeen(2);
      service.markQuoteSeen(3);

      final quote = service.getQuoteForDate(DateTime(2024, 6, 15));
      expect(quote, isNotNull);
      // Should not throw
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