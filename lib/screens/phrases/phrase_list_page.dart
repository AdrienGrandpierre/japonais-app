import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/phrase.dart';
import '../../widgets/phrase_card.dart';

class PhraseListPage extends StatefulWidget {
  const PhraseListPage({
    super.key,
    required this.phrases,
    required this.performance,
  });

  final List<Phrase> phrases;
  final Map<String, int> performance;

  @override
  State<PhraseListPage> createState() => _PhraseListPageState();
}

class _PhraseListPageState extends State<PhraseListPage>
    with AutomaticKeepAliveClientMixin {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  bool get wantKeepAlive => true;

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
    final score = widget.performance[phrase.key] ?? 0;
    return PhraseCard(
      phrase: phrase,
      score: score,
      onPlay: () => _speakJapanese(phrase.japanese),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

    // Titres toujours construits (pour « Aller à un groupe »), cartes construites à la demande.
    final slivers = <Widget>[
      for (final (i, entry) in grouped.entries.indexed) ...[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              entry.key,
              key: _categoryKeys[entry.key],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverList.builder(
            itemCount: entry.value.length,
            itemBuilder: (context, index) =>
                _buildPhraseCard(context, entry.value[index]),
          ),
        ),
      ],
    ];

    return SafeArea(
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
                    onChanged: (value) => setState(() => _searchQuery = value),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildCategoryMenuButton(grouped.keys.toList()),
              ],
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune phrase trouvée.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: slivers,
                  ),
          ),
        ],
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

  Future<void> _scrollToCategory(String category) async {
    // Attend la fermeture du menu.
    await Future.delayed(const Duration(milliseconds: 250));
    final ctx = _categoryKeys[category]?.currentContext;
    if (!mounted || ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // La hauteur des cartes pas encore construites est estimée : on recale une fois arrivé.
    final settled = _categoryKeys[category]?.currentContext;
    if (mounted && settled != null && settled.mounted) {
      await Scrollable.ensureVisible(settled);
    }
  }
}
