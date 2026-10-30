import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/reading_word.dart';
import '../../widgets/reading_word_views.dart';

/// Facile : QCM, le mot en grand → trouver son sens parmi 4 propositions.
class ReadingChoicePage extends StatefulWidget {
  const ReadingChoicePage({super.key, required this.words});

  final List<ReadingWord> words;

  @override
  State<ReadingChoicePage> createState() => _ReadingChoicePageState();
}

class _ReadingChoicePageState extends State<ReadingChoicePage>
    with AutomaticKeepAliveClientMixin {
  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  ReadingWord? _current;
  List<ReadingWord> _choices = [];
  int _correctIndex = 0;
  int? _selectedIndex;

  bool get _answered => _selectedIndex != null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.words.isNotEmpty) _prepareQuestion();
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

  void _prepareQuestion() {
    final words = widget.words;
    final candidates = words.length > 1
        ? words.where((w) => w != _current).toList()
        : words;
    final word = candidates[_random.nextInt(candidates.length)];

    // Distracteurs pris d'abord dans la même catégorie, complétés par les autres.
    final sameCategory =
        words.where((w) => w != word && w.category == word.category).toList()
          ..shuffle(_random);
    final others =
        words.where((w) => w != word && w.category != word.category).toList()
          ..shuffle(_random);
    final distractors = <ReadingWord>[];
    for (final w in [...sameCategory, ...others]) {
      if (distractors.length == 3) break;
      if (w.french == word.french ||
          distractors.any((d) => d.french == w.french)) {
        continue;
      }
      distractors.add(w);
    }

    _current = word;
    _choices = [word, ...distractors]..shuffle(_random);
    _correctIndex = _choices.indexOf(word);
    _selectedIndex = null;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _nextQuestion() => setState(_prepareQuestion);

  void _onChoiceTap(int index) {
    if (_answered) return;
    setState(() => _selectedIndex = index);
    if (index == _correctIndex) _tts.speak(_current!.japanese);
    // Fait apparaître la correction, affichée sous les choix.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Color _choiceColor(int index, ThemeData theme) {
    if (_answered && index == _correctIndex) return Colors.green.shade100;
    if (_answered && index == _selectedIndex) return Colors.red.shade100;
    return theme.colorScheme.surfaceContainerHighest;
  }

  Color _choiceBorderColor(int index) {
    if (_answered && index == _correctIndex) return Colors.green;
    if (_answered && index == _selectedIndex) return Colors.red;
    return Colors.transparent;
  }

  Widget _buildChoice(int i, ThemeData theme) {
    final choice = _choices[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _choiceColor(i, theme),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onChoiceTap(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _choiceBorderColor(i), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  choice.french,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                if (_answered && i != _correctIndex) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${choice.japanese}  ${choice.romanji}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final current = _current;
    if (current == null) {
      return const Center(child: Text('Aucun mot disponible.'));
    }

    final theme = Theme.of(context);
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
                    for (var i = 0; i < _choices.length; i++)
                      _buildChoice(i, theme),
                    if (_answered) ...[
                      const SizedBox(height: 6),
                      ReadingAnswer(
                        word: current,
                        correct: _selectedIndex == _correctIndex,
                        onSpeak: () => _tts.speak(current.japanese),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _answered ? _nextQuestion : null,
              child: const Text('Suivant'),
            ),
          ],
        ),
      ),
    );
  }
}
