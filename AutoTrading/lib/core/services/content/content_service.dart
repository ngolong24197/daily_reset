import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../models/quote.dart';
import '../../../models/trivia.dart';
import 'date_seeder.dart';

class ContentService {
  static const int _defaultTriviaCount = 3;

  List<Quote>? _quotesCache;
  List<TriviaQuestion>? _triviaCache;
  final DateSeeder _dateSeeder = DateSeeder();

  Future<void> init() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    final quotesJson = await rootBundle.loadString('assets/data/quotes.json');
    final triviaJson = await rootBundle.loadString('assets/data/trivia.json');

    final quotesList = jsonDecode(quotesJson) as List;
    final triviaList = jsonDecode(triviaJson) as List;

    _quotesCache = quotesList.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
    _triviaCache = triviaList.map((e) => TriviaQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Quote getQuoteForDate(DateTime date) {
    if (_quotesCache == null || _quotesCache!.isEmpty) {
      throw StateError('Quotes not loaded. Call init() first.');
    }
    final random = _dateSeeder.randomForFeature(date, 'quote');
    final index = random.nextInt(_quotesCache!.length);
    return _quotesCache![index];
  }

  List<TriviaQuestion> getTriviaForDate(DateTime date, {int? count}) {
    if (_triviaCache == null || _triviaCache!.isEmpty) {
      throw StateError('Trivia not loaded. Call init() first.');
    }
    final random = _dateSeeder.randomForFeature(date, 'trivia');

    // Determine how many questions (1-3) based on date seed
    final questionCount = count ?? (1 + random.nextInt(_defaultTriviaCount));
    final actualCount = questionCount.clamp(1, _triviaCache!.length);

    // Shuffle with date seed and take the first N
    final shuffled = List<TriviaQuestion>.from(_triviaCache!);
    shuffled.shuffle(random);

    return shuffled.take(actualCount).toList();
  }

  List<Quote> getAllQuotes() {
    return List.unmodifiable(_quotesCache ?? []);
  }

  Quote? getQuoteById(int id) {
    try {
      return _quotesCache?.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}