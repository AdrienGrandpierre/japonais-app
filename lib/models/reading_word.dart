class ReadingWord {
  final String japanese;
  final String romanji;
  final String french;
  final String context;
  final String category;

  const ReadingWord({
    required this.japanese,
    required this.romanji,
    required this.french,
    this.context = '',
    this.category = '',
  });

  String get key => '$japanese|$romanji';

  factory ReadingWord.fromJson(
    Map<String, dynamic> json, {
    String category = '',
  }) {
    return ReadingWord(
      japanese: json['japanese'] as String,
      romanji: json['romanji'] as String,
      french: json['french'] as String,
      context: json['context'] as String? ?? '',
      category: category,
    );
  }
}
