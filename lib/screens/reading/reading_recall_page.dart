import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/reading_word.dart';
import '../../widgets/reading_word_views.dart';

/// Normal : « de tête », le mot en grand → Dévoiler → Réussi / Raté.
/// Seul mode qui met à jour le score.
class ReadingRecallPage extends StatefulWidget {
  const ReadingRecallPage({
    super.key,
    required this.words,
    required this.performance,
    required this.onResult,
  });

  final List<ReadingWord> words;
  final Map<String, int> performance;
  final void Function(String key, bool correct) onResult;

  @override
  State<ReadingRecallPage> createState() => _ReadingRecallPageState();
}

class _ReadingRecallPageState extends State<ReadingRecallPage>
    with AutomaticKeepAliveClientMixin {
  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  ReadingWord? _current;
  bool _answerVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.words.isNotEmpty) _prepareWord();
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

  // Sélection pondérée : les mots mal maîtrisés reviennent plus souvent.
  ReadingWord _chooseWord() {
    final words = widget.words.length > 1
        ? widget.words.where((w) => w != _current).toList()
        : widget.words;
    final weights = [
      for (final w in words)
        (5 - (widget.performance[w.key] ?? 0)).clamp(1, 10),
    ];
    var target = _random.nextInt(weights.fold(0, (sum, w) => sum + w));
    for (var i = 0; i < words.length; i++) {
      target -= weights[i];
      if (target < 0) return words[i];
    }
    return words.first;
  }

  void _prepareWord() {
    _current = _chooseWord();
    _answerVisible = false;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _recordAnswer(bool correct) {
    widget.onResult(_current!.key, correct);
    setState(_prepareWord);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final current = _current;
    if (current == null) {
      return const Center(child: Text('Aucun mot disponible.'));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReadingPrompt(word: current),
                    const SizedBox(height: 16),
                    if (_answerVisible)
                      ReadingAnswer(
                        word: current,
                        onSpeak: () => _tts.speak(current.japanese),
                      )
                    else
                      Text(
                        'Que veut dire ce mot ? Comment se lit-il ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            if (_answerVisible)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _recordAnswer(false),
                      child: const Text('Raté'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _recordAnswer(true),
                      child: const Text('Réussi'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
