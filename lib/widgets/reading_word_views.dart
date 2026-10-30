import 'package:flutter/material.dart';

import '../models/reading_word.dart';

/// Mot à reconnaître, affiché en grand comme sur un panneau.
class ReadingPrompt extends StatelessWidget {
  const ReadingPrompt({super.key, required this.word});

  final ReadingWord word;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          word.japanese,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Correction d'un mot : romanji, sens, « où on le voit » et écoute.
/// [correct] colore la carte en vert / rouge (QCM) ; null = carte neutre.
class ReadingAnswer extends StatelessWidget {
  const ReadingAnswer({
    super.key,
    required this.word,
    required this.onSpeak,
    this.correct,
  });

  final ReadingWord word;
  final VoidCallback onSpeak;
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultColor = switch (correct) {
      true => Colors.green,
      false => Colors.red,
      null => null,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: switch (correct) {
          true => Colors.green.shade50,
          false => Colors.red.shade50,
          null => theme.colorScheme.secondary.withValues(alpha: 0.12),
        },
        borderRadius: BorderRadius.circular(14),
        border: resultColor == null ? null : Border.all(color: resultColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resultColor != null) ...[
            Row(
              children: [
                Icon(
                  correct! ? Icons.check_circle : Icons.cancel,
                  color: resultColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  correct! ? 'Correct !' : 'Raté !',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.romanji,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.french,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Écouter',
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up),
              ),
            ],
          ),
          if (word.context.isNotEmpty) ...[
            const Divider(height: 20),
            Text('Où on le voit', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(word.context, style: const TextStyle(fontSize: 15)),
          ],
        ],
      ),
    );
  }
}
