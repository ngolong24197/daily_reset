import 'dart:math';

class DateSeeder {
  /// Returns a deterministic integer seed from a date.
  /// Format: YYYYMMDD (e.g., 2024-04-17 -> 20240417)
  int dateSeed(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// Returns a deterministic Random instance for the given date.
  Random randomForDate(DateTime date) {
    return Random(dateSeed(date));
  }

  /// Returns a deterministic Random for a specific feature on a given date.
  /// Uses a different seed per feature to avoid correlation.
  Random randomForFeature(DateTime date, String feature) {
    final baseSeed = dateSeed(date);
    final featureHash = feature.hashCode;
    return Random(baseSeed ^ featureHash);
  }

  /// Returns a deterministic Random for a feature variant (used for replays).
  /// Each variant produces a different shuffle for the same date.
  Random randomForFeatureVariant(DateTime date, String feature, int variant) {
    final baseSeed = dateSeed(date);
    final featureHash = feature.hashCode;
    return Random(baseSeed ^ featureHash ^ (variant * 7919));
  }
}