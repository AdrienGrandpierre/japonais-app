import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  });

  final List<Phrase> phrases;
  final AppRoute currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Japonais App',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            selected: currentRoute == AppRoute.home,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Entraînement'),
            selected: currentRoute == AppRoute.training,
            enabled: phrases.isNotEmpty,
            onTap: currentRoute == AppRoute.training
                ? () => Navigator.pop(context)
                : () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AllPhrasesPage(phrases: phrases),
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
  final List<Phrase> _phrases = [];
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

  Future<void> _loadPhrases() async {
    final loaded = await PhraseRepository.loadPhrases();
    setState(() {
      _phrases.addAll(loaded);
      _loading = false;
      _pickNewQuestion();
    });
  }

  void _pickNewQuestion() {
    if (_phrases.isEmpty) {
      return;
    }

    final next = _phrases[_random.nextInt(_phrases.length)];
    final askFrench = _mode == QuizMode.mix
        ? _random.nextBool()
        : _mode == QuizMode.frenchToJapanese;

    setState(() {
      _currentPhrase = next;
      _answerVisible = false;
      _isFrenchPrompt = askFrench;
    });
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
      appBar: AppBar(title: const Text('1mois pour parler japonais')),
      drawer: AppDrawer(phrases: _phrases, currentRoute: AppRoute.home),
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
                    OutlinedButton(
                      onPressed: _pickNewQuestion,
                      child: const Text('Question suivante'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class AllPhrasesPage extends StatelessWidget {
  AllPhrasesPage({super.key, required this.phrases});

  final List<Phrase> phrases;
  final FlutterTts _tts = FlutterTts();

  Future<void> _speakJapanese(String text) async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Widget _buildPhraseCard(BuildContext context, Phrase phrase) {
    return PhraseCard(
      phrase: phrase,
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
      drawer: AppDrawer(phrases: phrases, currentRoute: AppRoute.training),
      body: SafeArea(
        bottom: true,
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
          children: phraseList,
        ),
      ),
    );
  }
}

class PhraseCard extends StatefulWidget {
  const PhraseCard({super.key, required this.phrase, required this.onPlay});

  final Phrase phrase;
  final VoidCallback onPlay;

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
