import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../enums/quiz_mode.dart';
import '../../models/phrase.dart';

class PhraseQuizPage extends StatefulWidget {
  const PhraseQuizPage({
    super.key,
    required this.phrases,
    required this.performance,
    required this.onResult,
    required this.revisionRequest,
  });

  final List<Phrase> phrases;
  final Map<String, int> performance;
  final void Function(String key, bool correct) onResult;

  /// Incrémenté par l'Accueil pour relancer le quiz en Français → Japonais.
  final int revisionRequest;

  @override
  State<PhraseQuizPage> createState() => _PhraseQuizPageState();
}

class _PhraseQuizPageState extends State<PhraseQuizPage>
    with AutomaticKeepAliveClientMixin {
  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  late Phrase _currentPhrase;
  QuizMode _mode = QuizMode.frenchToJapanese;
  bool _answerVisible = false;
  bool _isFrenchPrompt = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.phrases.isNotEmpty) _nextPhrase();
  }

  @override
  void didUpdateWidget(PhraseQuizPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revisionRequest != widget.revisionRequest &&
        widget.phrases.isNotEmpty) {
      _mode = QuizMode.frenchToJapanese;
      _nextPhrase();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  int _phraseWeight(Phrase phrase) {
    final performance = widget.performance[phrase.key] ?? 0;
    return (5 - performance).clamp(1, 10);
  }

  Phrase _choosePhrase() {
    final phrases = widget.phrases;
    final weights = phrases.map(_phraseWeight).toList();
    final totalWeight = weights.fold<int>(0, (sum, weight) => sum + weight);
    var target = _random.nextInt(totalWeight);

    for (var i = 0; i < phrases.length; i++) {
      target -= weights[i];
      if (target < 0) return phrases[i];
    }
    return phrases.first;
  }

  void _nextPhrase() {
    _currentPhrase = _choosePhrase();
    _answerVisible = false;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _isFrenchPrompt = _mode == QuizMode.mix
        ? _random.nextBool()
        : _mode == QuizMode.frenchToJapanese;
  }

  void _pickNewQuestion() => setState(_nextPhrase);

  void _recordAnswerResult(bool correct) {
    if (_mode == QuizMode.frenchToJapanese) {
      widget.onResult(_currentPhrase.key, correct);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.phrases.isEmpty) {
      return const Center(child: Text('Aucune phrase disponible.'));
    }
    return SafeArea(
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
                  onSelected: (_) => _changeMode(QuizMode.frenchToJapanese),
                ),
                ChoiceChip(
                  label: const Text('Japonais → Français'),
                  selected: _mode == QuizMode.japaneseToFrench,
                  onSelected: (_) => _changeMode(QuizMode.japaneseToFrench),
                ),
                ChoiceChip(
                  label: const Text('Mixte'),
                  selected: _mode == QuizMode.mix,
                  onSelected: (_) => _changeMode(QuizMode.mix),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
    );
  }
}
