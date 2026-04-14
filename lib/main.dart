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

enum QuizMode { mix, frenchToJapanese, japaneseToFrench }

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
  QuizMode _mode = QuizMode.mix;
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
      drawer: Drawer(
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
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Entraînement'),
              onTap: _phrases.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AllPhrasesPage(phrases: _phrases),
                        ),
                      );
                    },
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entraînement')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: phrases.length,
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phrase.japanese,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            phrase.romanji,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            phrase.french,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _speakJapanese(phrase.japanese),
                          icon: const Icon(Icons.volume_up),
                          splashRadius: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
