import 'dart:math';

import 'package:flutter/material.dart';

import '../data/performance_repository.dart';
import '../data/phrase_repository.dart';
import '../data/reading_repository.dart';
import '../enums/app_section.dart';
import '../models/phrase.dart';
import '../models/reading_word.dart';
import 'home_page.dart';
import 'phrases/phrases_section.dart';
import 'reading/reading_section.dart';
import 'verbs/verbs_section.dart';

/// Racine de l'app : barre de navigation en bas + un écran par module.
/// Charge les phrases, les mots de lecture et les scores une seule fois et les partage.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final List<Phrase> _phrases = [];
  final Map<String, int> _performance = {};
  final List<ReadingWord> _readingWords = [];
  final Map<String, int> _readingPerformance = {};
  bool _loading = true;
  AppSection _section = AppSection.home;
  int _revisionRequest = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final phrases = await PhraseRepository.loadPhrases();
    final performance = await PerformanceRepository.phrases.load();
    for (final phrase in phrases) {
      performance.putIfAbsent(phrase.key, () => 0);
    }
    final readingWords = await ReadingRepository.loadWords();
    final readingPerformance = await PerformanceRepository.reading.load();
    for (final word in readingWords) {
      readingPerformance.putIfAbsent(word.key, () => 0);
    }
    setState(() {
      _phrases.addAll(phrases);
      _performance.addAll(performance);
      _readingWords.addAll(readingWords);
      _readingPerformance.addAll(readingPerformance);
      _loading = false;
    });
  }

  // Le score est une série : +N = N réussites d'affilée, -N = N ratés d'affilée.
  void _recordResult(
    PerformanceRepository repository,
    Map<String, int> scores,
    String key,
    bool correct,
  ) {
    final score = scores[key] ?? 0;
    setState(() {
      scores[key] = correct
          ? (max(score, 0) + 1).clamp(-5, 5)
          : (min(score, 0) - 1).clamp(-5, 5);
    });
    repository.save(scores);
  }

  void _resetScores(
    PerformanceRepository repository,
    Map<String, int> scores,
    Iterable<String> keys,
  ) {
    setState(() {
      scores
        ..clear()
        ..addEntries(keys.map((k) => MapEntry(k, 0)));
    });
    repository.save(scores);
  }

  void _startRevision() {
    setState(() {
      _section = AppSection.phrases;
      _revisionRequest++;
    });
  }

  Widget _buildSection(AppSection section) => switch (section) {
    AppSection.home => HomePage(
      phrases: _phrases,
      performance: _performance,
      readingWords: _readingWords,
      readingPerformance: _readingPerformance,
      onStartRevision: _startRevision,
      onOpenSection: (s) => setState(() => _section = s),
    ),
    AppSection.phrases => PhrasesSection(
      phrases: _phrases,
      performance: _performance,
      onResult: (key, correct) => _recordResult(
        PerformanceRepository.phrases,
        _performance,
        key,
        correct,
      ),
      onReset: () => _resetScores(
        PerformanceRepository.phrases,
        _performance,
        _phrases.map((p) => p.key),
      ),
      revisionRequest: _revisionRequest,
    ),
    AppSection.verbs => const VerbsSection(),
    AppSection.reading => ReadingSection(
      words: _readingWords,
      performance: _readingPerformance,
      onResult: (key, correct) => _recordResult(
        PerformanceRepository.reading,
        _readingPerformance,
        key,
        correct,
      ),
      onReset: () => _resetScores(
        PerformanceRepository.reading,
        _readingPerformance,
        _readingWords.map((w) => w.key),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Retour depuis un autre onglet : revenir à l'Accueil au lieu de fermer l'app.
    return PopScope(
      canPop: _section == AppSection.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _section = AppSection.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _section.index,
          children: [for (final s in AppSection.values) _buildSection(s)],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _section.index,
          onDestinationSelected: (i) =>
              setState(() => _section = AppSection.values[i]),
          destinations: [
            for (final s in AppSection.values)
              NavigationDestination(
                icon: Icon(s.icon),
                selectedIcon: Icon(s.selectedIcon),
                label: s.label,
              ),
          ],
        ),
      ),
    );
  }
}
