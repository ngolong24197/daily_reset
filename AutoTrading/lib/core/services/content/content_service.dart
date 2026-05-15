import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../../../models/quote.dart';
import '../../../models/trivia.dart';
import '../../../core/constants/content_urls.dart';
import 'date_seeder.dart';

class ContentService {
  static const int _defaultTriviaCount = 3;
  static const double _refreshThreshold = 0.8;

  List<Quote> _quotes = [];
  List<TriviaQuestion> _trivia = [];
  final Set<int> _seenQuoteIds = {};
  final Set<int> _seenTriviaIds = {};
  final DateSeeder _dateSeeder = DateSeeder();
  int _installSeed = 0;

  // Callbacks for persisting seen state
  void Function(int quoteId)? onQuoteSeen;
  void Function(List<int> triviaIds)? onTriviaSeen;

  ContentService();

  ContentService.withData({List<Quote>? quotes, List<TriviaQuestion>? trivia}) {
    _quotes = quotes ?? [];
    _trivia = trivia ?? [];
  }

  /// Set the install-specific seed. Each install gets a different seed,
  /// so content varies across reinstalls while staying stable within a session.
  void setInstallSeed(int seed) {
    _installSeed = seed;
  }

  Future<void> init() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    final quotesJson = await rootBundle.loadString('assets/data/quotes.json');
    final triviaJson = await rootBundle.loadString('assets/data/trivia.json');

    final quotesList = jsonDecode(quotesJson) as List;
    final triviaList = jsonDecode(triviaJson) as List;

    _quotes = quotesList.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
    _trivia = triviaList.map((e) => TriviaQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  void loadSeenIds({List<int>? quoteIds, List<int>? triviaIds}) {
    _seenQuoteIds.clear();
    _seenTriviaIds.clear();
    if (quoteIds != null) _seenQuoteIds.addAll(quoteIds);
    if (triviaIds != null) _seenTriviaIds.addAll(triviaIds);
  }

  void loadRemoteContent({List<Quote>? quotes, List<TriviaQuestion>? trivia}) {
    if (quotes != null) mergeRemoteQuotes(quotes);
    if (trivia != null) mergeRemoteTrivia(trivia);
  }

  /// Returns the quote for a given date using deterministic date-seeded selection
  /// combined with an install-specific seed. Same install + same date = same quote.
  /// Different install = different quote, even on the same date.
  Quote getQuoteForDate(DateTime date) {
    if (_quotes.isEmpty) {
      throw StateError('Quotes not loaded. Call init() first.');
    }
    final baseSeed = _dateSeeder.dateSeed(date) ^ _installSeed;
    final random = Random(baseSeed ^ 'quote'.hashCode);
    final index = random.nextInt(_quotes.length);
    return _quotes[index];
  }

  /// Returns trivia questions for a given date using deterministic date-seeded selection.
  /// Install seed varies content across reinstalls. Variant shifts seed for replays.
  List<TriviaQuestion> getTriviaForDate(DateTime date, {int? count, int variant = 0}) {
    if (_trivia.isEmpty) {
      throw StateError('Trivia not loaded. Call init() first.');
    }
    final baseSeed = _dateSeeder.dateSeed(date) ^ _installSeed;
    final random = variant == 0
        ? Random(baseSeed ^ 'trivia'.hashCode)
        : Random(baseSeed ^ 'trivia'.hashCode ^ (variant * 7919));

    final questionCount = count ?? (1 + random.nextInt(_defaultTriviaCount));
    final actualCount = questionCount.clamp(1, _trivia.length);

    final shuffled = List<TriviaQuestion>.from(_trivia)..shuffle(random);
    return shuffled.take(actualCount).toList();
  }

  void markQuoteSeen(int id) {
    _seenQuoteIds.add(id);
    onQuoteSeen?.call(id);
  }

  void markTriviaSeen(List<int> ids) {
    _seenTriviaIds.addAll(ids);
    onTriviaSeen?.call(ids);
  }

  bool get needsQuoteRefresh {
    if (_quotes.isEmpty) return false;
    return _seenQuoteIds.length / _quotes.length >= _refreshThreshold;
  }

  bool get needsTriviaRefresh {
    if (_trivia.isEmpty) return false;
    return _seenTriviaIds.length / _trivia.length >= _refreshThreshold;
  }

  int get totalQuoteCount => _quotes.length;
  int get totalTriviaCount => _trivia.length;

  void mergeRemoteQuotes(List<Quote> remote) {
    final existingIds = _quotes.map((q) => q.id).toSet();
    final newQuotes = remote.where((q) => !existingIds.contains(q.id)).toList();
    _quotes.addAll(newQuotes);
  }

  void mergeRemoteTrivia(List<TriviaQuestion> remote) {
    final existingIds = _trivia.map((t) => t.id).toSet();
    final newTrivia = remote.where((t) => !existingIds.contains(t.id)).toList();
    _trivia.addAll(newTrivia);
  }

  Future<ContentRefreshResult> refreshFromRemote() async {
    bool quotesOk = false;
    bool triviaOk = false;
    String? quotesError;
    String? triviaError;

    try {
      final response = await http.get(Uri.parse(ContentUrls.quotes));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        final remoteQuotes = list.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
        mergeRemoteQuotes(remoteQuotes);
        quotesOk = true;
      } else {
        quotesError = 'Server returned ${response.statusCode}';
      }
    } catch (e) {
      quotesError = e.toString();
    }

    try {
      final response = await http.get(Uri.parse(ContentUrls.trivia));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        final remoteTrivia = list.map((e) => TriviaQuestion.fromJson(e as Map<String, dynamic>)).toList();
        mergeRemoteTrivia(remoteTrivia);
        triviaOk = true;
      } else {
        triviaError = 'Server returned ${response.statusCode}';
      }
    } catch (e) {
      triviaError = e.toString();
    }

    return ContentRefreshResult(
      quotesSuccess: quotesOk,
      triviaSuccess: triviaOk,
      quotesError: quotesError,
      triviaError: triviaError,
    );
  }

  List<Quote> getAllQuotes() {
    return List.unmodifiable(_quotes);
  }

  List<TriviaQuestion> getAllTrivia() {
    return List.unmodifiable(_trivia);
  }

  Quote? getQuoteById(int id) {
    try {
      return _quotes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}

class ContentRefreshResult {
  final bool quotesSuccess;
  final bool triviaSuccess;
  final String? quotesError;
  final String? triviaError;

  ContentRefreshResult({
    required this.quotesSuccess,
    required this.triviaSuccess,
    this.quotesError,
    this.triviaError,
  });

  bool get partialSuccess => quotesSuccess || triviaSuccess;
  bool get totalSuccess => quotesSuccess && triviaSuccess;
  bool get totalFailure => !quotesSuccess && !triviaSuccess;
}