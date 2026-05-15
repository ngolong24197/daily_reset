class Quote {
  final int id;
  final String text;
  final String author;
  final String meaning;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.meaning,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'] as int,
        text: json['text'] as String,
        author: json['author'] as String,
        meaning: json['meaning'] as String,
      );
}