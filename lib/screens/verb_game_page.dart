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
  // Familles de formes faciles à confondre, utilisées comme distracteurs en mode normal
  static const _formFamilies = [
    ['past_polite', 'past_casual', 'negative_polite', 'negative_casual'],
    ['progressive', 'permission', 'try'],
    ['want', 'potential', 'imperative'],
  ];
  static final _registerSuffix = RegExp(r'\s*\((poli|familier)\)$');

  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();

  List<Verb> _verbs = [];
  List<Phrase> _phrases = [];
  bool _loading = true;

  VerbDifficulty _difficulty = VerbDifficulty.normal;
  late Verb _currentVerb;
  late VerbForm _targetForm;
  List<_VerbChoice> _choices = [];
  int _correctIndex = 0;
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
    final otherVerbs = _verbs.where((v) => v != verb).toList()
      ..shuffle(_random);

    final _VerbChoice correct;
    final List<_VerbChoice> distractors;
    switch (_difficulty) {
      case VerbDifficulty.easy:
        correct = _verbChoice(verb);
        distractors = otherVerbs.take(3).map(_verbChoice).toList();
      case VerbDifficulty.normal:
        correct = _formChoice(verb, target);
        distractors = _pickDistractorKeys(
          verb,
          targetKey,
        ).map((k) => _formChoice(verb, verb.forms[k]!)).toList();
      case VerbDifficulty.hard:
        correct = _formChoice(verb, target);
        distractors = otherVerbs
            .where((v) => v.forms.containsKey(targetKey))
            .take(3)
            .map((v) => _formChoice(v, v.forms[targetKey]!))
            .toList();
    }

    final choices = [correct, ...distractors]..shuffle(_random);

    setState(() {
      _currentVerb = verb;
      _targetForm = target;
      _choices = choices;
      _correctIndex = choices.indexOf(correct);
      _selectedIndex = null;
    });
  }

  List<String> _pickDistractorKeys(Verb verb, String targetKey) {
    final family = _formFamilies.firstWhere(
      (f) => f.contains(targetKey),
      orElse: () => const [],
    );
    final close =
        family
            .where((k) => k != targetKey && verb.forms.containsKey(k))
            .toList()
          ..shuffle(_random);
    final others =
        verb.forms.keys
            .where((k) => k != targetKey && !close.contains(k))
            .toList()
          ..shuffle(_random);
    return [...close, ...others].take(3).toList();
  }

  _VerbChoice _verbChoice(Verb verb) => _VerbChoice(
    japanese: verb.japanese,
    romanji: verb.romanji,
    detail: verb.french,
  );

  _VerbChoice _formChoice(Verb verb, VerbForm form) => _VerbChoice(
    japanese: form.japanese,
    romanji: form.romanji,
    detail: _difficulty == VerbDifficulty.hard
        ? '${verb.french} · ${_formLabel(form.key)}'
        : _formLabel(form.key),
  );

  void _changeDifficulty(VerbDifficulty difficulty) {
    if (difficulty == _difficulty) return;
    _difficulty = difficulty;
    _nextQuestion();
  }

  void _onChoiceTap(int index) {
    if (_answered) return;
    setState(() => _selectedIndex = index);
    if (index == _correctIndex) {
      _tts.speak(_choices[_correctIndex].japanese);
    }
  }

  Color _choiceColor(int index) {
    if (!_answered)
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    final isCorrect = index == _correctIndex;
    final isSelected = index == _selectedIndex;
    if (isCorrect) return Colors.green.shade100;
    if (isSelected) return Colors.red.shade100;
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color _choiceBorderColor(int index) {
    if (!_answered) return Colors.transparent;
    final isCorrect = index == _correctIndex;
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

  String _difficultyLabel(VerbDifficulty difficulty) => switch (difficulty) {
    VerbDifficulty.easy => 'Facile',
    VerbDifficulty.normal => 'Normal',
    VerbDifficulty.hard => 'Difficile',
  };

  Widget _buildDifficultySelector() {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final d in VerbDifficulty.values)
          ChoiceChip(
            label: Text(_difficultyLabel(d)),
            selected: _difficulty == d,
            onSelected: (_) => _changeDifficulty(d),
          ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFormBadge(ThemeData theme) {
    final register = _targetForm.register;
    final registerColor = switch (register) {
      'poli' => Colors.blue.shade700,
      'familier' => Colors.deepOrange.shade700,
      _ => null,
    };
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildChip(
          _formLabel(_targetForm.key).replaceAll(_registerSuffix, ''),
          theme.colorScheme.primary,
        ),
        if (registerColor != null)
          _buildChip(
            '${register[0].toUpperCase()}${register.substring(1)}',
            registerColor,
          ),
      ],
    );
  }

  Widget _buildConjugatedFrench(ThemeData theme) {
    return Text(
      '« ${_targetForm.french.replaceAll(_registerSuffix, '')} »',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onPrimaryContainer,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCorrectAnswer(_VerbChoice choice, ThemeData theme) {
    final word = choice.japanese;
    final base = _currentVerb.japanese;
    var stem = 0;
    if (_difficulty != VerbDifficulty.easy) {
      while (stem < word.length &&
          stem < base.length &&
          word[stem] == base[stem]) {
        stem++;
      }
    } else {
      stem = word.length;
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        children: [
          TextSpan(text: word.substring(0, stem)),
          TextSpan(
            text: word.substring(stem),
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          TextSpan(text: '  ${choice.romanji}'),
        ],
      ),
    );
  }

  Widget _buildPrompt(ThemeData theme) {
    final onContainer = theme.colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: switch (_difficulty) {
          VerbDifficulty.easy => [
            Text(
              _currentVerb.french,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: onContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          VerbDifficulty.normal => [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _currentVerb.japanese,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: onContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _currentVerb.romanji,
                  style: TextStyle(
                    fontSize: 15,
                    color: onContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
            Text(
              _currentVerb.french,
              style: TextStyle(
                fontSize: 14,
                color: onContainer.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 16),
            _buildConjugatedFrench(theme),
            const SizedBox(height: 10),
            _buildFormBadge(theme),
          ],
          VerbDifficulty.hard => [
            _buildConjugatedFrench(theme),
            const SizedBox(height: 10),
            _buildFormBadge(theme),
          ],
        },
      ),
    );
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
    final isCorrect = _answered && _selectedIndex == _correctIndex;
    final correctChoice = _choices[_correctIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Verbes')),
      drawer: AppDrawer(
        phrases: _phrases,
        currentRoute: AppRoute.verbs,
        onNavigateToTraining: _navigateToTraining,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildDifficultySelector(),
            ),
            Expanded(
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
                          _buildPrompt(theme),
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
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              choice.japanese,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              choice.romanji,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_answered) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            choice.detail,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
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
                                        isCorrect
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.red,
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
                                      if (_difficulty !=
                                          VerbDifficulty.easy) ...[
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _formLabel(_targetForm.key),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildCorrectAnswer(correctChoice, theme),
                                  if (_difficulty == VerbDifficulty.easy)
                                    Text(
                                      _currentVerb.french,
                                      style: const TextStyle(fontSize: 16),
                                    )
                                  else ...[
                                    if (_difficulty == VerbDifficulty.hard)
                                      Text(
                                        '${_currentVerb.japanese}  ${_currentVerb.romanji} — ${_currentVerb.french}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
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
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
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
          ],
        ),
      ),
    );
  }
}

class _VerbChoice {
  const _VerbChoice({
    required this.japanese,
    required this.romanji,
    required this.detail,
  });

  final String japanese;
  final String romanji;
  final String detail;
}
