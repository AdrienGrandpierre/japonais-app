import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/phrase_repository.dart';
import 'models/phrase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Japonais App';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.phrases,
    required this.currentRoute,
    this.phrasePerformance = const {},
  });

  final List<Phrase> phrases;
  final AppRoute currentRoute;
  final Map<String, int> phrasePerformance;

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive ? color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? color
                      : enabled
                          ? null
                          : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive
                          ? color
                          : enabled
                              ? null
                              : Colors.grey,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Japonais App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentRoute == AppRoute.home
                        ? 'Accueil'
                        : 'Entraînement',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _drawerItem(
            context: context,
            icon: Icons.home,
            label: 'Accueil',
            isActive: currentRoute == AppRoute.home,
            enabled: true,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          _drawerItem(
            context: context,
            icon: Icons.menu_book,
            label: 'Entraînement',
            isActive: currentRoute == AppRoute.training,
            enabled: phrases.isNotEmpty,
            onTap: currentRoute == AppRoute.training
                ? () => Navigator.pop(context)
                : () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AllPhrasesPage(
                          phrases: phrases,
                          phrasePerformance: phrasePerformance,
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

enum QuizMode { mix, frenchToJapanese, japaneseToFrench }

enum AppRoute { home, training }

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
    _loadPhrases();
  }

  String _phraseKey(Phrase phrase) =>
      '${phrase.japanese}|${phrase.romanji}|${phrase.french}';

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
      _phrasePerformance.putIfAbsent(_phraseKey(phrase), () => 0);
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
    }
  }

  Future<void> _loadPhrases() async {
    final loaded = await PhraseRepository.loadPhrases();
    await _loadPerformance();
    setState(() {
      _phrases.addAll(loaded);
      _initializePerformance(loaded);
      _loading = false;
      _pickNewQuestion();
    });
  }

  int _phraseWeight(Phrase phrase) {
    final performance = _phrasePerformance[_phraseKey(phrase)] ?? 0;
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
    final key = _phraseKey(_currentPhrase);
    final currentScore = _phrasePerformance[key] ?? 0;
    final updatedScore = (currentScore + (correct ? 1 : -1)).clamp(-5, 5);
    _phrasePerformance[key] = updatedScore;
    await _savePerformance();
    _pickNewQuestion();
  }

  void _changeMode(QuizMode mode) {
    setState(() {
      _mode = mode;
    });
    _pickNewQuestion();
  }

  Future<void> _speakJapanese() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
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
                        ).colorScheme.secondary.withOpacity(0.12),
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

class AllPhrasesPage extends StatelessWidget {
  AllPhrasesPage({
    super.key,
    required this.phrases,
    this.phrasePerformance = const {},
  });

  final List<Phrase> phrases;
  final Map<String, int> phrasePerformance;
  final FlutterTts _tts = FlutterTts();

  String _phraseKey(Phrase phrase) =>
      '${phrase.japanese}|${phrase.romanji}|${phrase.french}';

  Future<void> _speakJapanese(String text) async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Widget _buildPhraseCard(BuildContext context, Phrase phrase) {
    final score = phrasePerformance[_phraseKey(phrase)] ?? 0;
    return PhraseCard(
      phrase: phrase,
      score: score,
      onPlay: () => _speakJapanese(phrase.japanese),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Phrase>>{};
    for (final phrase in phrases) {
      final category = phrase.category.isEmpty ? 'Autres' : phrase.category;
      grouped.putIfAbsent(category, () => []).add(phrase);
    }

    final phraseList = grouped.entries
        .expand<Widget>(
          (entry) => [
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...entry.value.map((phrase) => _buildPhraseCard(context, phrase)),
            const SizedBox(height: 20),
          ],
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Entraînement')),
      drawer: AppDrawer(
        phrases: phrases,
        currentRoute: AppRoute.training,
        phrasePerformance: phrasePerformance,
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: phraseList,
        ),
      ),
    );
  }
}

class PhraseCard extends StatefulWidget {
  const PhraseCard({
    super.key,
    required this.phrase,
    required this.onPlay,
    this.score = 0,
  });

  final Phrase phrase;
  final VoidCallback onPlay;
  final int score;

  @override
  State<PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<PhraseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            widget.phrase.context.isNotEmpty || widget.phrase.dialog.isNotEmpty
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                    
                    ScoreBox(score: widget.score),
                    const SizedBox(width: 12),                 
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.phrase.japanese,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.phrase.romanji,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.phrase.french,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: widget.onPlay,
                        icon: const Icon(Icons.volume_up),
                        splashRadius: 28,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.phrase.context.isNotEmpty ||
                  widget.phrase.dialog.isNotEmpty) ...[
                const SizedBox(height: 12),
                AnimatedCrossFade(
                  firstChild: const Text(
                    '...',
                    style: TextStyle(color: Colors.grey),
                  ),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.phrase.context.isNotEmpty) ...[
                          Text(
                            widget.phrase.context,
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (widget.phrase.dialog.isNotEmpty)
                            const SizedBox(height: 12),
                        ],
                        if (widget.phrase.dialog.isNotEmpty) ...[
                          Text(
                            'Dialogue',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          ...widget.phrase.dialog.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      ],
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ScoreBox extends StatelessWidget {
  const ScoreBox({required this.score});

  final int score;

  double get normalized => score / 5.0; // -1 → 1

  Color get _color {
    final t = (normalized + 1) / 2; // 0 → red, 1 → green
    return Color.lerp(Colors.red, Colors.green, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 60, // ajuste si besoin
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        normalized == 0 ? "0" : normalized.toStringAsFixed(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}