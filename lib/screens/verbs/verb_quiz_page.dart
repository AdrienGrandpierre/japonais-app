import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../enums/quiz_mode.dart';
import '../../models/verb.dart';

class VerbQuizPage extends StatefulWidget {
  const VerbQuizPage({
    super.key,
    required this.verbs,
    required this.difficulty,
  });

  final List<Verb> verbs;
  final VerbDifficulty difficulty;

  @override
  State<VerbQuizPage> createState() => _VerbQuizPageState();
}

class _VerbQuizPageState extends State<VerbQuizPage>
    with AutomaticKeepAliveClientMixin {
  // Familles de formes faciles à confondre, utilisées comme distracteurs en mode normal
  static const _formFamilies = [
    ['past_polite', 'past_casual', 'negative_polite', 'negative_casual'],
    ['progressive', 'permission', 'try'],
    ['want', 'potential', 'imperative'],
  ];
  static final _registerSuffix = RegExp(r'\s*\((poli|familier)\)$');
  // Formes les plus utiles à l'oral, montrées en correction du mode facile
  static const _commonForms = [
    'past_polite',
    'negative_polite',
    'progressive',
    'want',
  ];

  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  VerbDifficulty get _difficulty => widget.difficulty;
  late Verb _currentVerb;
  late VerbForm _targetForm;
  List<_VerbChoice> _choices = [];
  int _correctIndex = 0;
  int? _selectedIndex;
  bool get _answered => _selectedIndex != null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.verbs.isNotEmpty) _prepareQuestion();
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
    final verbs = widget.verbs;
    final verb = verbs[_random.nextInt(verbs.length)];
    final formKeys = verb.forms.keys.toList();
    final targetKey = formKeys[_random.nextInt(formKeys.length)];
    final target = verb.forms[targetKey]!;
    final otherVerbs = verbs.where((v) => v != verb).toList()..shuffle(_random);

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

    _currentVerb = verb;
    _targetForm = target;
    _choices = choices;
    _correctIndex = choices.indexOf(correct);
    _selectedIndex = null;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _nextQuestion() => setState(_prepareQuestion);

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
        ? '${verb.french} · ${form.label}'
        : form.label,
  );

  void _onChoiceTap(int index) {
    if (_answered) return;
    setState(() => _selectedIndex = index);
    if (index == _correctIndex) {
      _tts.speak(_choices[_correctIndex].japanese);
    }
    // Fait apparaître le feedback, affiché sous les choix.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Color _choiceColor(int index) {
    if (!_answered) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
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
          _targetForm.label.replaceAll(_registerSuffix, ''),
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

  Widget _buildChoice(int i, ThemeData theme) {
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _choiceBorderColor(i), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(choice.japanese, style: const TextStyle(fontSize: 20)),
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
                if (_answered) ...[
                  const SizedBox(height: 4),
                  Text(
                    choice.detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
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

  Widget _buildCommonForm(VerbForm form, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            form.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: form.japanese,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '  ${form.romanji}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(form.french, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFeedback(ThemeData theme) {
    final isCorrect = _selectedIndex == _correctIndex;
    final color = isCorrect ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct !' : 'Raté !',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              if (_difficulty != VerbDifficulty.easy) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _targetForm.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _buildCorrectAnswer(_choices[_correctIndex], theme),
          if (_difficulty == VerbDifficulty.easy) ...[
            Text(_currentVerb.french, style: const TextStyle(fontSize: 16)),
            const Divider(height: 20),
            Text('Formes courantes', style: theme.textTheme.labelLarge),
            for (final key in _commonForms)
              if (_currentVerb.forms[key] case final form?)
                _buildCommonForm(form, theme),
          ] else ...[
            if (_difficulty == VerbDifficulty.hard)
              Text(
                '${_currentVerb.japanese}  ${_currentVerb.romanji} — ${_currentVerb.french}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
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
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.verbs.isEmpty) {
      return const Center(child: Text('Aucun verbe disponible.'));
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
                    _buildPrompt(theme),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _choices.length; i++)
                      _buildChoice(i, theme),
                    if (_answered) ...[
                      const SizedBox(height: 6),
                      _buildFeedback(theme),
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
