import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../../models/streak.dart';
import '../../../models/mood.dart';

class PersistenceService {
  static const String streakBoxName = 'streak';
  static const String moodBoxName = 'moods';
  static const String settingsBoxName = 'settings';
  static const String premiumBoxName = 'premium';
  static const String seenContentBoxName = 'seenContent';
  static const String remoteContentBoxName = 'remoteContent';

  late Box<dynamic> _streakBox;
  late Box<dynamic> _moodBox;
  late Box<dynamic> _settingsBox;
  late Box<dynamic> _premiumBox;
  late Box<dynamic> _seenContentBox;
  late Box<dynamic> _remoteContentBox;

  StreakData get streak {
    final data = _streakBox.get('streak');
    if (data == null) return StreakData();
    return StreakData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Box<dynamic> get moodBox => _moodBox;
  Box<dynamic> get settingsBox => _settingsBox;
  Box<dynamic> get premiumBox => _premiumBox;
  Box<dynamic> get seenContentBox => _seenContentBox;
  Box<dynamic> get remoteContentBox => _remoteContentBox;

  Future<void> init() async {
    await Hive.initFlutter();

    _streakBox = await _openBoxSafe(streakBoxName);
    _moodBox = await _openBoxSafe(moodBoxName);
    _settingsBox = await _openBoxSafe(settingsBoxName);
    _premiumBox = await _openBoxSafe(premiumBoxName);
    _seenContentBox = await _openBoxSafe(seenContentBoxName);
    _remoteContentBox = await _openBoxSafe(remoteContentBoxName);
  }

  Future<Box<dynamic>> _openBoxSafe(String name) async {
    try {
      return await Hive.openBox<dynamic>(name);
    } catch (_) {
      // Box corrupted — delete and recreate
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<dynamic>(name);
    }
  }

  Future<void> saveStreak(StreakData data) async {
    await _streakBox.put('streak', data.toJson());
  }

  Future<void> saveMoodEntry(MoodEntry entry) async {
    await _moodBox.put(entry.date, entry.toJson());
  }

  MoodEntry? getMoodEntry(String date) {
    final data = _moodBox.get(date);
    if (data == null) return null;
    return MoodEntry.fromJson(Map<String, dynamic>.from(data as Map));
  }

  bool isPremium() {
    return _premiumBox.get('isPremium', defaultValue: false) as bool;
  }

  Future<void> setPremium(bool value) async {
    await _premiumBox.put('isPremium', value);
  }

  List<String> getFavoriteQuotes() {
    return List<String>.from(
      _settingsBox.get('favoriteQuotes', defaultValue: <String>[]) as List,
    );
  }

  Future<void> toggleFavoriteQuote(String quoteId) async {
    final favorites = getFavoriteQuotes();
    if (favorites.contains(quoteId)) {
      favorites.remove(quoteId);
    } else {
      favorites.add(quoteId);
    }
    await _settingsBox.put('favoriteQuotes', favorites);
  }

  bool isQuoteFavorite(String quoteId) {
    return getFavoriteQuotes().contains(quoteId);
  }

  Set<String> getCompletedFeatures(String date) {
    final key = 'completed_$date';
    return Set<String>.from(
      _settingsBox.get(key, defaultValue: <String>[]) as List,
    );
  }

  Future<void> markFeatureCompleted(String date, String feature) async {
    final completed = getCompletedFeatures(date);
    completed.add(feature);
    await _settingsBox.put('completed_$date', completed.toList());
  }

  // --- Seen-content methods ---

  List<int> getSeenQuoteIds() {
    return List<int>.from(_seenContentBox.get('seen_quote_ids', defaultValue: <int>[]) as List);
  }

  Future<void> addSeenQuoteId(int id) async {
    final ids = getSeenQuoteIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _seenContentBox.put('seen_quote_ids', ids);
    }
  }

  Future<void> setSeenQuoteIds(List<int> ids) async {
    await _seenContentBox.put('seen_quote_ids', ids);
  }

  List<int> getSeenTriviaIds() {
    return List<int>.from(_seenContentBox.get('seen_trivia_ids', defaultValue: <int>[]) as List);
  }

  Future<void> addSeenTriviaIds(List<int> newIds) async {
    final existing = getSeenTriviaIds();
    final merged = [...existing, ...newIds.where((id) => !existing.contains(id))];
    await _seenContentBox.put('seen_trivia_ids', merged);
  }

  Future<void> setSeenTriviaIds(List<int> ids) async {
    await _seenContentBox.put('seen_trivia_ids', ids);
  }

  // --- Remote-content cache methods ---

  List<Map<String, dynamic>>? getCachedRemoteQuotes() {
    final data = _remoteContentBox.get('quotes');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<void> setCachedRemoteQuotes(List<Map<String, dynamic>> quotes) async {
    await _remoteContentBox.put('quotes', quotes);
  }

  List<Map<String, dynamic>>? getCachedRemoteTrivia() {
    final data = _remoteContentBox.get('trivia');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<void> setCachedRemoteTrivia(List<Map<String, dynamic>> trivia) async {
    await _remoteContentBox.put('trivia', trivia);
  }
}