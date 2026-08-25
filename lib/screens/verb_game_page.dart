import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/phrase_repository.dart';
import '../data/verb_repository.dart';
import '../enums/quiz_mode.dart';
import '../models/phrase.dart';
import '../models/verb.dart';
import '../screens/all_phrases_page.dart';
import '../widgets/app_drawer.dart';

class VerbGamePage extends StatefulWidget {
  const VerbGamePage({super.key});

  @override
  State<VerbGamePage> createState() => _VerbGamePageState();
}

class _VerbGamePageState extends State<VerbGamePage> {
  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();

  List<Verb> _verbs = [];
  List<Phrase> _phrases = [];
  bool _loading = true;

  late Verb _currentVerb;
  late VerbForm _targetForm;
  List<VerbForm> _choices = [];
  int? _selectedIndex;
  bool get _answered => _selectedIndex != null;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadVerbs();
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

  Future<void> _loadVerbs() async {
    final verbs = await VerbRepository.loadVerbs();
    final phrases = await PhraseRepository.loadPhrases();
    setState(() {
      _verbs = verbs;
      _phrases = phrases;
      _loading = false;
    });
    _nextQuestion();
  }

  void _navigateToTraining() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllPhrasesPage(phrases: _phrases),
      ),
    );
  }

  void _nextQuestion() {
    if (_verbs.isEmpty) return;

    final verb = _verbs[_random.nextInt(_verbs.length)];
    final formKeys = verb.forms.keys.toList();
    final targetKey = formKeys[_random.nextInt(formKeys.length)];
    final target = verb.forms[targetKey]!;

    final distractorKeys = formKeys.where((k) => k != targetKey).toList()
      ..shuffle(_random);
    final distractors = distractorKeys
        .take(3)
        .map((k) => verb.forms[k]!)
        .toList();

    final choices = [target, ...distractors]..shuffle(_random);

    setState(() {
      _currentVerb = verb;
      _targetForm = target;
      _choices = choices;
      _selectedIndex = null;
    });
  }

  void _onChoiceTap(int index) {
    if (_answered) return;
    setState(() => _selectedIndex = index);
    if (_choices[index].key == _targetForm.key) {
      _tts.speak(_targetForm.japanese);
    }
  }

  Color _choiceColor(int index) {
    if (!_answered)
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    final isCorrect = _choices[index].key == _targetForm.key;
    final isSelected = index == _selectedIndex;
    if (isCorrect) return Colors.green.shade100;
    if (isSelected) return Colors.red.shade100;
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color _choiceBorderColor(int index) {
    if (!_answered) return Colors.transparent;
    final isCorrect = _choices[index].key == _targetForm.key;
    final isSelected = index == _selectedIndex;
    if (isCorrect) return Colors.green;
    if (isSelected) return Colors.red;
    return Colors.transparent;
  }

  String _formLabel(String key) {
    const labels = {
      'past_polite': 'Passé (poli)',
      'past_casual': 'Passé (familier)',
      'negative_polite': 'Négatif (poli)',
      'negative_casual': 'Négatif (familier)',
      'want': 'Vouloir',
      'progressive': 'Progressif',
      'permission': 'Permission',
      'potential': 'Potentiel',
      'imperative': 'Impératif',
      'try': 'Essayer',
    };
    return labels[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verbes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isCorrect =
        _answered && _choices[_selectedIndex!].key == _targetForm.key;

    return Scaffold(
      appBar: AppBar(title: const Text('Verbes')),
      drawer: AppDrawer(
        phrases: _phrases,
        currentRoute: AppRoute.verbs,
        onNavigateToTraining: _navigateToTraining,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Verb name
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentVerb.japanese,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_currentVerb.romanji} — ${_currentVerb.french}',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formLabel(_targetForm.key),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '« ${_targetForm.french} »',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Choices
                    ...List.generate(_choices.length, (i) {
                      final choice = _choices[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: _choiceColor(i),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _onChoiceTap(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _choiceBorderColor(i),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    choice.japanese,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    choice.romanji,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Feedback + example
                    if (_answered) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCorrect ? 'Correct !' : 'Raté !',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formLabel(_targetForm.key),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_targetForm.japanese}  ${_targetForm.romanji}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 16),
                            Text(
                              _targetForm.example.japanese,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              _targetForm.example.romanji,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _targetForm.example.french,
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _nextQuestion,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Suivant'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
