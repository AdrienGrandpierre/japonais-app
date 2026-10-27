enum QuizMode { mix, frenchToJapanese, japaneseToFrench }

enum VerbDifficulty {
  easy('Facile'),
  normal('Normal'),
  hard('Difficile');

  const VerbDifficulty(this.label);

  final String label;
}
