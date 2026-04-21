import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/phrase_repository.dart';
import '../enums/quiz_mode.dart';
import '../models/phrase.dart';
import '../widgets/app_drawer.dart';
import 'all_phrases_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _performanceKey = 'phrasePerformance';

  final List<Phrase> _phrases = [];
  final Map<String, int> _phrasePerformance = {};
  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();
  late Phrase _currentPhrase;
  QuizMode _mode = QuizMode.frenchToJapanese;
  bool _answerVisible = false;
  bool _isFrenchPrompt = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadPhrases();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _loadPerformance() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_performanceKey);
    if (stored == null) {
      return;
    }

    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is int) {
            _phrasePerformance[entry.key] = value.clamp(-5, 5);
          } else if (value is String) {
            _phrasePerformance[entry.key] =
                int.tryParse(value)?.clamp(-5, 5) ?? 0;
          }
        }
      }
    } catch (_) {
      // Ignore invalid stored data and start fresh.
    }
  }

  Future<void> _savePerformance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_performanceKey, jsonEncode(_phrasePerformance));
  }

  void _initializePerformance(List<Phrase> loaded) {
    for (final phrase in loaded) {
      _phrasePerformance.putIfAbsent(phrase.key, () => 0);
    }
  }

  Future<void> _resetPerformance() async {
    _phrasePerformance.clear();
    _initializePerformance(_phrases);
    await _savePerformance();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores de quiz réinitialisés.')),
      );
      setState(() {});
      _pickNewQuestion();
    }
  }

  Future<void> _loadPhrases() async {
    final loaded = await PhraseRepository.loadPhrases();
    await _loadPerformance();
    _phrases.addAll(loaded);
    _initializePerformance(loaded);
    setState(() => _loading = false);
    _pickNewQuestion();
  }

  int _phraseWeight(Phrase phrase) {
    final performance = _phrasePerformance[phrase.key] ?? 0;
    return (5 - performance).clamp(1, 10);
  }

  void _pickNewQuestion() {
    if (_phrases.isEmpty) {
      return;
    }

    final weights = _phrases.map(_phraseWeight).toList();
    final totalWeight = weights.fold<int>(0, (sum, weight) => sum + weight);
    var target = _random.nextInt(totalWeight);
    var next = _phrases.first;

    for (var i = 0; i < _phrases.length; i++) {
      target -= weights[i];
      if (target < 0) {
        next = _phrases[i];
        break;
      }
    }

    final askFrench = _mode == QuizMode.mix
        ? _random.nextBool()
        : _mode == QuizMode.frenchToJapanese;

    setState(() {
      _currentPhrase = next;
      _answerVisible = false;
      _isFrenchPrompt = askFrench;
    });
  }

  Future<void> _recordAnswerResult(bool correct) async {
    if (_mode == QuizMode.frenchToJapanese) {
      final key = _currentPhrase.key;
      final currentScore = _phrasePerformance[key] ?? 0;
      final updatedScore = (currentScore + (correct ? 1 : -1)).clamp(-5, 5);
      _phrasePerformance[key] = updatedScore;
      await _savePerformance();
    }
    _pickNewQuestion();
  }

  void _changeMode(QuizMode mode) {
    _mode = mode;
    _pickNewQuestion();
  }

  Future<void> _speakJapanese() async {
    await _tts.speak(_currentPhrase.japanese);
  }

  String get _promptLabel {
    if (_mode == QuizMode.frenchToJapanese) {
      return 'Français';
    }
    if (_mode == QuizMode.japaneseToFrench) {
      return 'Japonais / Romanji';
    }
    return _isFrenchPrompt ? 'Français' : 'Japonais / Romanji';
  }

  String get _promptText {
    if (_mode == QuizMode.frenchToJapanese ||
        (_mode == QuizMode.mix && _isFrenchPrompt)) {
      return _currentPhrase.french;
    }
    return '${_currentPhrase.romanji}\n${_currentPhrase.japanese}';
  }

  String get _answerText {
    if (_mode == QuizMode.frenchToJapanese ||
        (_mode == QuizMode.mix && _isFrenchPrompt)) {
      return '${_currentPhrase.romanji}\n${_currentPhrase.japanese}';
    }
    return _currentPhrase.french;
  }

  String get _answerLabel {
    if (_mode == QuizMode.frenchToJapanese ||
        (_mode == QuizMode.mix && _isFrenchPrompt)) {
      return 'Romanji + Japonais';
    }
    return 'Traduction française';
  }

  void _navigateToTraining() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllPhrasesPage(
          phrases: _phrases,
          phrasePerformance: _phrasePerformance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1mois pour parler japonais'),
        actions: [
          IconButton(
            tooltip: 'Réinitialiser scores quiz',
            icon: const Icon(Icons.refresh),
            onPressed: _resetPerformance,
          ),
        ],
      ),
      drawer: AppDrawer(
        phrases: _phrases,
        currentRoute: AppRoute.home,
        phrasePerformance: _phrasePerformance,
        onNavigateToTraining: _navigateToTraining,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Mode de quiz',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Français → Japonais'),
                          selected: _mode == QuizMode.frenchToJapanese,
                          onSelected: (_) =>
                              _changeMode(QuizMode.frenchToJapanese),
                        ),
                        ChoiceChip(
                          label: const Text('Japonais → Français'),
                          selected: _mode == QuizMode.japaneseToFrench,
                          onSelected: (_) =>
                              _changeMode(QuizMode.japaneseToFrench),
                        ),
                        ChoiceChip(
                          label: const Text('Mixte'),
                          selected: _mode == QuizMode.mix,
                          onSelected: (_) => _changeMode(QuizMode.mix),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _promptLabel,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _promptText,
                              style: const TextStyle(
                                fontSize: 22,
                                height: 1.35,
                              ),
                            ),
                            if (_mode == QuizMode.japaneseToFrench ||
                                (_mode == QuizMode.mix && !_isFrenchPrompt))
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: OutlinedButton.icon(
                                  onPressed: _speakJapanese,
                                  icon: const Icon(Icons.volume_up),
                                  label: const Text('Écouter le japonais'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_answerVisible)
                      Card(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.12),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _answerLabel,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _answerText,
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.35,
                                ),
                              ),
                              if (_currentPhrase.context.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Contexte',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentPhrase.context,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                              if (_currentPhrase.dialog.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Dialogue',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                ..._currentPhrase.dialog.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          line.japanese,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          line.romanji,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          line.french,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (_mode == QuizMode.frenchToJapanese ||
                                  (_mode == QuizMode.mix && _isFrenchPrompt))
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: OutlinedButton.icon(
                                    onPressed: _speakJapanese,
                                    icon: const Icon(Icons.volume_up),
                                    label: const Text('Écouter le japonais'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _answerVisible
                          ? null
                          : () => setState(() => _answerVisible = true),
                      child: const Text('Dévoiler'),
                    ),
                    const SizedBox(height: 12),
                    if (_answerVisible) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _recordAnswerResult(false),
                              child: const Text('Raté'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _recordAnswerResult(true),
                              child: const Text('Réussi'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
