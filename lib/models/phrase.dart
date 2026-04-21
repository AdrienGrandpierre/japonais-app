class PhraseDialogLine {
  final String japanese;
  final String romanji;
  final String french;

  const PhraseDialogLine({
    required this.japanese,
    required this.romanji,
    required this.french,
  });

  factory PhraseDialogLine.fromJson(Map<String, dynamic> json) {
    return PhraseDialogLine(
      japanese: json['japanese'] as String? ?? '',
      romanji: json['romanji'] as String? ?? '',
      french: json['french'] as String? ?? '',
    );
  }
}

class Phrase {
  final String japanese;
  final String romanji;
  final String french;
  final String context;
  final String category;
  final List<PhraseDialogLine> dialog;

  const Phrase({
    required this.japanese,
    required this.romanji,
    required this.french,
    this.context = '',
    this.category = '',
    this.dialog = const [],
  });

  String get key => '$japanese|$romanji|$french';

  factory Phrase.fromJson(Map<String, dynamic> json, {String category = ''}) {
    final dialogJson = json['dialog'] ?? json['dialogs'];
    final dialogLines = <PhraseDialogLine>[];

    if (dialogJson is List) {
      for (final item in dialogJson) {
        if (item is Map<String, dynamic>) {
          dialogLines.add(PhraseDialogLine.fromJson(item));
        } else if (item is Map) {
          dialogLines.add(PhraseDialogLine.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }

    return Phrase(
      japanese: json['japanese'] as String,
      romanji: json['romanji'] as String,
      french: json['french'] as String,
      context: json['context'] as String? ?? '',
      category: category,
      dialog: dialogLines,
    );
  }
}
