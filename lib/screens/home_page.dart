import 'package:flutter/material.dart';

import '../enums/app_section.dart';
import '../models/phrase.dart';
import '../models/reading_word.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.phrases,
    required this.performance,
    required this.readingWords,
    required this.readingPerformance,
    required this.onStartRevision,
    required this.onOpenSection,
  });

  final List<Phrase> phrases;
  final Map<String, int> performance;
  final List<ReadingWord> readingWords;
  final Map<String, int> readingPerformance;
  final VoidCallback onStartRevision;
  final ValueChanged<AppSection> onOpenSection;

  String _sectionSubtitle(AppSection section) => switch (section) {
    AppSection.home => '',
    AppSection.phrases => '${phrases.length} phrases · quiz et liste',
    AppSection.verbs => 'Conjugaisons · facile, normal, difficile',
    AppSection.reading =>
      '${readingWords.length} mots à reconnaître · facile, normal, liste',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phraseScores = [
      for (final phrase in phrases) performance[phrase.key] ?? 0,
    ];
    final readingScores = [
      for (final word in readingWords) readingPerformance[word.key] ?? 0,
    ];
    final toReview = phraseScores.where((s) => s <= -2).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Hanasō')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Prêt à pratiquer ?', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    toReview > 0
                        ? '$toReview ${toReview > 1 ? 'phrases' : 'phrase'} à revoir'
                        : 'Quiz Français → Japonais',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onStartRevision,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Réviser maintenant'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Progression des phrases', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _ProgressCard(scores: phraseScores, masteredLabel: 'Maîtrisées'),
          const SizedBox(height: 20),
          Text('Progression lecture', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _ProgressCard(scores: readingScores, masteredLabel: 'Maîtrisés'),
          const SizedBox(height: 20),
          Text('Modules', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final section in AppSection.values)
            if (section != AppSection.home)
              Card(
                child: ListTile(
                  leading: Icon(
                    section.selectedIcon,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(section.label),
                  subtitle: Text(_sectionSubtitle(section)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenSection(section),
                ),
              ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.scores, required this.masteredLabel});

  final List<int> scores;
  final String masteredLabel;

  @override
  Widget build(BuildContext context) {
    // Maîtrisé = 4 réussites d'affilée, à revoir = 2 ratés d'affilée.
    final mastered = scores.where((s) => s >= 4).length;
    final toReview = scores.where((s) => s <= -2).length;
    final learning = scores.length - mastered - toReview;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: scores.isEmpty ? 0 : mastered / scores.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatTile(
                  label: masteredLabel,
                  count: mastered,
                  color: Colors.green,
                ),
                _StatTile(
                  label: 'En cours',
                  count: learning,
                  color: Colors.blueGrey,
                ),
                _StatTile(
                  label: 'À revoir',
                  count: toReview,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
