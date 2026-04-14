class Phrase {
  final String japanese;
  final String romanji;
  final String french;

  const Phrase({
    required this.japanese,
    required this.romanji,
    required this.french,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      japanese: json['japanese'] as String,
      romanji: json['romanji'] as String,
      french: json['french'] as String,
    );
  }
}
