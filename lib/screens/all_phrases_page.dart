import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../enums/quiz_mode.dart';
import '../models/phrase.dart';
import '../widgets/app_drawer.dart';
import '../widgets/phrase_card.dart';

class AllPhrasesPage extends StatefulWidget {
  const AllPhrasesPage({
    super.key,
    required this.phrases,
    this.phrasePerformance = const {},
  });

  final List<Phrase> phrases;
  final Map<String, int> phrasePerformance;

  @override
  State<AllPhrasesPage> createState() => _AllPhrasesPageState();
}

class _AllPhrasesPageState extends State<AllPhrasesPage> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _speakJapanese(String text) async {
    await _tts.speak(text);
  }

  Widget _buildPhraseCard(BuildContext context, Phrase phrase) {
    final score = widget.phrasePerformance[phrase.key] ?? 0;
    return PhraseCard(
      phrase: phrase,
      score: score,
      onPlay: () => _speakJapanese(phrase.japanese),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase().trim();
    final filteredPhrases = query.isEmpty
        ? widget.phrases
        : widget.phrases
              .where((p) => p.french.toLowerCase().contains(query))
              .toList();

    final grouped = <String, List<Phrase>>{};
    for (final phrase in filteredPhrases) {
      final category = phrase.category.isEmpty ? 'Autres' : phrase.category;
      grouped.putIfAbsent(category, () => []).add(phrase);
    }

    for (final category in grouped.keys) {
      _categoryKeys.putIfAbsent(category, () => GlobalKey());
    }

    final phraseList = grouped.entries
        .expand<Widget>(
          (entry) => [
            Text(
              entry.key,
              key: _categoryKeys[entry.key],
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
        phrases: widget.phrases,
        currentRoute: AppRoute.training,
        phrasePerformance: widget.phrasePerformance,
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une traduction...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryMenuButton(grouped.keys.toList()),
                ],
              ),
            ),
            Expanded(
              child: phraseList.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune phrase trouvée.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      cacheExtent: 100000,
                      children: phraseList,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryMenuButton(List<String> categories) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.list),
      tooltip: 'Aller à un groupe',
      onSelected: _scrollToCategory,
      itemBuilder: (context) => categories
          .map(
            (category) =>
                PopupMenuItem<String>(value: category, child: Text(category)),
          )
          .toList(),
    );
  }

  void _scrollToCategory(String category) {
    // Wait for the popup menu's close animation so the key's context is stable.
    Future.delayed(const Duration(milliseconds: 250), () {
      final key = _categoryKeys[category];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }
}
