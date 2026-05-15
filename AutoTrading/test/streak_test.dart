import 'package:flutter_test/flutter_test.dart';
import 'package:daily_reset/core/providers.dart';
import 'package:daily_reset/core/services/persistence/persistence_service.dart';
import 'package:daily_reset/models/streak.dart';

/// Mock PersistenceService for testing StreakNotifier
class MockPersistenceService extends PersistenceService {
  StreakData _streakData = StreakData();
  bool _premium = false;
  List<String> _favorites = [];
  Map<String, Set<String>> _completed = {};
  List<int> _seenQuoteIds = [];
  List<int> _seenTriviaIds = [];
  List<Map<String, dynamic>>? _cachedRemoteQuotes;
  List<Map<String, dynamic>>? _cachedRemoteTrivia;

  @override
  StreakData get streak => _streakData;

  @override
  Future<void> saveStreak(StreakData data) async {
    _streakData = data;
  }

  @override
  bool isPremium() => _premium;

  @override
  Future<void> setPremium(bool value) async {
    _premium = value;
  }

  @override
  List<String> getFavoriteQuotes() => _favorites;

  @override
  Future<void> toggleFavoriteQuote(String quoteId) async {
    if (_favorites.contains(quoteId)) {
      _favorites.remove(quoteId);
    } else {
      _favorites.add(quoteId);
    }
  }

  @override
  Set<String> getCompletedFeatures(String date) {
    return _completed[date] ?? {};
  }

  @override
  Future<void> markFeatureCompleted(String date, String feature) async {
    _completed.putIfAbsent(date, () => {});
    _completed[date]!.add(feature);
  }

  // --- Seen-content methods ---

  @override
  List<int> getSeenQuoteIds() => _seenQuoteIds;

  @override
  Future<void> addSeenQuoteId(int id) async {
    if (!_seenQuoteIds.contains(id)) {
      _seenQuoteIds.add(id);
    }
  }

  @override
  Future<void> setSeenQuoteIds(List<int> ids) async {
    _seenQuoteIds = ids;
  }

  @override
  List<int> getSeenTriviaIds() => _seenTriviaIds;

  @override
  Future<void> addSeenTriviaIds(List<int> newIds) async {
    for (final id in newIds) {
      if (!_seenTriviaIds.contains(id)) {
        _seenTriviaIds.add(id);
      }
    }
  }

  @override
  Future<void> setSeenTriviaIds(List<int> ids) async {
    _seenTriviaIds = ids;
  }

  // --- Remote-content cache methods ---

  @override
  List<Map<String, dynamic>>? getCachedRemoteQuotes() => _cachedRemoteQuotes;

  @override
  Future<void> setCachedRemoteQuotes(List<Map<String, dynamic>> quotes) async {
    _cachedRemoteQuotes = quotes;
  }

  @override
  List<Map<String, dynamic>>? getCachedRemoteTrivia() => _cachedRemoteTrivia;

  @override
  Future<void> setCachedRemoteTrivia(List<Map<String, dynamic>> trivia) async {
    _cachedRemoteTrivia = trivia;
  }
}

void main() {
  group('StreakNotifier', () {
    late MockPersistenceService mockPersistence;
    late StreakNotifier notifier;

    setUp(() {
      mockPersistence = MockPersistenceService();
      notifier = StreakNotifier(mockPersistence);
    });

    test('initial state has zero streak', () {
      expect(notifier.state.currentStreak, 0);
      expect(notifier.state.bestStreak, 0);
    });

    test('first update starts streak at 1', () {
      final today = DateTime(2024, 4, 17);
      notifier.updateStreak(today);

      expect(notifier.state.currentStreak, 1);
      expect(notifier.state.bestStreak, 1);
      expect(notifier.state.lastActiveDate, '2024-04-17');
    });

    test('consecutive day increments streak', () {
      final day1 = DateTime(2024, 4, 16);
      final day2 = DateTime(2024, 4, 17);

      notifier.updateStreak(day1);
      expect(notifier.state.currentStreak, 1);

      notifier.updateStreak(day2);
      expect(notifier.state.currentStreak, 2);
      expect(notifier.state.bestStreak, 2);
    });

    test('same day does not increment streak', () {
      final today = DateTime(2024, 4, 17);

      notifier.updateStreak(today);
      expect(notifier.state.currentStreak, 1);

      notifier.updateStreak(today);
      expect(notifier.state.currentStreak, 1);
    });

    test('missed day resets streak to 1', () {
      final day1 = DateTime(2024, 4, 15);
      final day3 = DateTime(2024, 4, 17); // skipped day2

      notifier.updateStreak(day1);
      expect(notifier.state.currentStreak, 1);

      notifier.updateStreak(day3);
      expect(notifier.state.currentStreak, 1); // reset
    });

    test('best streak is preserved after reset', () {
      // Build a 5-day streak
      for (int i = 0; i < 5; i++) {
        notifier.updateStreak(DateTime(2024, 4, 10 + i));
      }
      expect(notifier.state.currentStreak, 5);
      expect(notifier.state.bestStreak, 5);

      // Skip a day, reset
      notifier.updateStreak(DateTime(2024, 4, 20));
      expect(notifier.state.currentStreak, 1);
      expect(notifier.state.bestStreak, 5); // preserved
    });

    test('7-day streak milestone detection', () {
      for (int i = 0; i < 7; i++) {
        notifier.updateStreak(DateTime(2024, 4, 10 + i));
      }

      final hit = notifier.checkMilestone(7);
      expect(hit, true);
      expect(notifier.state.milestones['7'], true);
    });

    test('milestone not triggered twice', () {
      for (int i = 0; i < 3; i++) {
        notifier.updateStreak(DateTime(2024, 4, 10 + i));
      }

      final hit1 = notifier.checkMilestone(3);
      expect(hit1, true);

      final hit2 = notifier.checkMilestone(3);
      expect(hit2, false); // already triggered
    });

    test('milestone not triggered for wrong day', () {
      for (int i = 0; i < 3; i++) {
        notifier.updateStreak(DateTime(2024, 4, 10 + i));
      }

      final hit = notifier.checkMilestone(7);
      expect(hit, false);
    });

    test('completed dates track all active days', () {
      notifier.updateStreak(DateTime(2024, 4, 15));
      notifier.updateStreak(DateTime(2024, 4, 16));

      expect(notifier.state.completedDates, contains('2024-04-15'));
      expect(notifier.state.completedDates, contains('2024-04-16'));
      expect(notifier.state.completedDates.length, 2);
    });

    test('30-day streak increments correctly', () {
      for (int i = 0; i < 30; i++) {
        notifier.updateStreak(DateTime(2024, 3, 1 + i));
      }

      expect(notifier.state.currentStreak, 30);
      expect(notifier.state.bestStreak, 30);

      final hit = notifier.checkMilestone(30);
      expect(hit, true);
    });
  });

  group('DailyProgressNotifier', () {
    late MockPersistenceService mockPersistence;

    setUp(() {
      mockPersistence = MockPersistenceService();
    });

    test('initially no features completed', () {
      final notifier = DailyProgressNotifier(mockPersistence, DateTime(2024, 4, 17));
      expect(notifier.state, isEmpty);
    });

    test('markCompleted adds feature', () async {
      final notifier = DailyProgressNotifier(mockPersistence, DateTime(2024, 4, 17));
      await notifier.markCompleted('morning');

      expect(notifier.state, contains('morning'));
    });

    test('isCompleted returns true for completed feature', () async {
      final notifier = DailyProgressNotifier(mockPersistence, DateTime(2024, 4, 17));
      await notifier.markCompleted('brain');

      expect(notifier.isCompleted('brain'), true);
      expect(notifier.isCompleted('morning'), false);
    });

    test('all three features can be completed', () async {
      final notifier = DailyProgressNotifier(mockPersistence, DateTime(2024, 4, 17));
      await notifier.markCompleted('morning');
      await notifier.markCompleted('brain');
      await notifier.markCompleted('reflection');

      expect(notifier.state.length, 3);
      expect(notifier.isCompleted('morning'), true);
      expect(notifier.isCompleted('brain'), true);
      expect(notifier.isCompleted('reflection'), true);
    });
  });

  group('PremiumNotifier', () {
    late MockPersistenceService mockPersistence;

    setUp(() {
      mockPersistence = MockPersistenceService();
    });

    test('initial state is not premium', () {
      final notifier = PremiumNotifier(mockPersistence);
      expect(notifier.state, false);
    });

    test('setPremium updates state', () async {
      final notifier = PremiumNotifier(mockPersistence);
      await notifier.setPremium(true);

      expect(notifier.state, true);
    });

    test('premium can be toggled off', () async {
      final notifier = PremiumNotifier(mockPersistence);
      await notifier.setPremium(true);
      expect(notifier.state, true);

      await notifier.setPremium(false);
      expect(notifier.state, false);
    });
  });
}