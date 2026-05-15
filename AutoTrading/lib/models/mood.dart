enum Mood {
  great,
  good,
  okay,
  low,
  rough,
}

class MoodEntry {
  final String id;
  final String date;
  final Mood mood;
  final String journalText;
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.journalText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'mood': mood.index,
        'journalText': journalText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    final moodIndex = json['mood'] as int;
    return MoodEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      mood: moodIndex >= 0 && moodIndex < Mood.values.length
          ? Mood.values[moodIndex]
          : Mood.okay,
      journalText: json['journalText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}