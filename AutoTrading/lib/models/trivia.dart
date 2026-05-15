class TriviaQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;

  TriviaQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) => TriviaQuestion(
        id: json['id'] as int,
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
        correctIndex: json['correctIndex'] as int,
        explanation: json['explanation'] as String,
        category: json['category'] as String,
      );
}