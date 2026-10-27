import 'package:flutter/material.dart';

import '../enums/app_section.dart';
import '../models/phrase.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.phrases,
    required this.performance,
    required this.onStartRevision,
    required this.onOpenSection,
  });

  final List<Phrase> phrases;
  final Map<String, int> performance;
  final VoidCallback onStartRevision;
  final ValueChanged<AppSection> onOpenSection;

  String _sectionSubtitle(AppSection section) => switch (section) {
    AppSection.home => '',
    AppSection.phrases => '${phrases.length} phrases · quiz et liste',
    AppSection.verbs => 'Conjugaisons · facile, normal, difficile',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var mastered = 0;
    var toReview = 0;
    for (final phrase in phrases) {
      final score = performance[phrase.key] ?? 0;
      if (score >= 4) {
        mastered++;
      } else if (score <= -2) {
        toReview++;
      }
    }
    final learning = phrases.length - mastered - toReview;

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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: phrases.isEmpty ? 0 : mastered / phrases.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatTile(
                        label: 'Maîtrisées',
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
          ),
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
