class StreakData {
  int currentStreak;
  int bestStreak;
  String lastActiveDate;
  List<String> completedDates;
  Map<String, dynamic> milestones;

  StreakData({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastActiveDate = '',
    this.completedDates = const [],
    this.milestones = const {},
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastActiveDate': lastActiveDate,
        'completedDates': completedDates,
        'milestones': milestones,
      };

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastActiveDate: json['lastActiveDate'] as String? ?? '',
        completedDates: List<String>.from(json['completedDates'] as List? ?? []),
        milestones: Map<String, dynamic>.from(json['milestones'] as Map? ?? {}),
      );
}