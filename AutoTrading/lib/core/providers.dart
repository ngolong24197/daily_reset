import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/persistence/persistence_service.dart';
import 'services/content/content_service.dart';
import 'services/ad/ad_service.dart';
import 'services/sound/sound_service.dart';
import 'services/notification/notification_service.dart';
import '../models/streak.dart';

final persistenceProvider = Provider<PersistenceService>((ref) {
  throw UnimplementedError('PersistenceService must be overridden');
});

final contentProvider = Provider<ContentService>((ref) {
  throw UnimplementedError('ContentService must be overridden');
});

final streakProvider = StateNotifierProvider<StreakNotifier, StreakData>((ref) {
  throw UnimplementedError('StreakNotifier must be overridden');
});

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  throw UnimplementedError('PremiumNotifier must be overridden');
});

final dailyProgressProvider = StateNotifierProvider<DailyProgressNotifier, Set<String>>((ref) {
  throw UnimplementedError('DailyProgressNotifier must be overridden');
});

final dateProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

final adServiceProvider = Provider<AdService>((ref) {
  throw UnimplementedError('AdService must be overridden');
});

final soundServiceProvider = Provider<SoundService>((ref) {
  throw UnimplementedError('SoundService must be overridden');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService must be overridden');
});

final milestoneReachedProvider = StateProvider<int?>((ref) => null);

class StreakNotifier extends StateNotifier<StreakData> {
  final PersistenceService _persistence;

  StreakNotifier(this._persistence) : super(_persistence.streak);

  void updateStreak(DateTime today) {
    final todayStr = _formatDate(today);
    final lastActive = state.lastActiveDate;

    if (lastActive.isEmpty) {
      // First time ever
      state = StreakData(
        currentStreak: 1,
        bestStreak: 1,
        lastActiveDate: todayStr,
        completedDates: [...state.completedDates, todayStr],
        milestones: state.milestones,
      );
    } else if (lastActive == todayStr) {
      // Already active today, no change
      return;
    } else if (_isYesterday(lastActive, today)) {
      // Consecutive day
      final newStreak = state.currentStreak + 1;
      state = StreakData(
        currentStreak: newStreak,
        bestStreak: math.max(newStreak, state.bestStreak),
        lastActiveDate: todayStr,
        completedDates: [...state.completedDates, todayStr],
        milestones: state.milestones,
      );
    } else {
      // Missed days, reset
      state = StreakData(
        currentStreak: 1,
        bestStreak: state.bestStreak,
        lastActiveDate: todayStr,
        completedDates: [...state.completedDates, todayStr],
        milestones: state.milestones,
      );
    }

    _persistence.saveStreak(state);
  }

  bool checkMilestone(int days) {
    if (state.currentStreak == days && !(state.milestones[days.toString()] as bool? ?? false)) {
      state = StreakData(
        currentStreak: state.currentStreak,
        bestStreak: state.bestStreak,
        lastActiveDate: state.lastActiveDate,
        completedDates: state.completedDates,
        milestones: {...state.milestones, days.toString(): true},
      );
      _persistence.saveStreak(state);
      return true;
    }
    return false;
  }

  int? checkMilestones() {
    for (final days in [3, 7, 30]) {
      if (checkMilestone(days)) return days;
    }
    return null;
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isYesterday(String lastDateStr, DateTime today) {
    final lastDate = DateTime.parse(lastDateStr);
    final yesterday = today.subtract(const Duration(days: 1));
    return lastDate.year == yesterday.year &&
        lastDate.month == yesterday.month &&
        lastDate.day == yesterday.day;
  }
}

class PremiumNotifier extends StateNotifier<bool> {
  final PersistenceService _persistence;

  PremiumNotifier(this._persistence) : super(_persistence.isPremium());

  Future<void> setPremium(bool value) async {
    state = value;
    await _persistence.setPremium(value);
  }
}

class DailyProgressNotifier extends StateNotifier<Set<String>> {
  final PersistenceService _persistence;
  final DateTime _today;

  DailyProgressNotifier(this._persistence, this._today)
      : super(_persistence.getCompletedFeatures(_formatDate(_today)));

  Future<void> markCompleted(String feature) async {
    final todayStr = _formatDate(_today);
    state = {...state, feature};
    await _persistence.markFeatureCompleted(todayStr, feature);
  }

  bool isCompleted(String feature) => state.contains(feature);

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}