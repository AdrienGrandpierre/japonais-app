import 'dart:math';

import 'package:flutter/material.dart';

import '../data/performance_repository.dart';
import '../data/phrase_repository.dart';
import '../enums/app_section.dart';
import '../models/phrase.dart';
import 'home_page.dart';
import 'phrases/phrases_section.dart';
import 'verbs/verbs_section.dart';

/// Racine de l'app : barre de navigation en bas + un écran par module.
/// Charge les phrases et les scores une seule fois et les partage.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final List<Phrase> _phrases = [];
  final Map<String, int> _performance = {};
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
    final performance = await PerformanceRepository.load();
    for (final phrase in phrases) {
      performance.putIfAbsent(phrase.key, () => 0);
    }
    setState(() {
      _phrases.addAll(phrases);
      _performance.addAll(performance);
      _loading = false;
    });
  }

  // Le score est une série : +N = N réussites d'affilée, -N = N ratés d'affilée.
  void _recordResult(String key, bool correct) {
    final score = _performance[key] ?? 0;
    setState(() {
      _performance[key] = correct
          ? (max(score, 0) + 1).clamp(-5, 5)
          : (min(score, 0) - 1).clamp(-5, 5);
    });
    PerformanceRepository.save(_performance);
  }

  void _resetPerformance() {
    setState(() {
      _performance
        ..clear()
        ..addEntries(_phrases.map((p) => MapEntry(p.key, 0)));
    });
    PerformanceRepository.save(_performance);
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
      onStartRevision: _startRevision,
      onOpenSection: (s) => setState(() => _section = s),
    ),
    AppSection.phrases => PhrasesSection(
      phrases: _phrases,
      performance: _performance,
      onResult: _recordResult,
      onReset: _resetPerformance,
      revisionRequest: _revisionRequest,
    ),
    AppSection.verbs => const VerbsSection(),
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
