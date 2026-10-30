import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/reading_word.dart';
import '../../widgets/score_box.dart';

/// Liste : lexique groupé par catégorie avec le score de chaque mot.
class ReadingListPage extends StatefulWidget {
  const ReadingListPage({
    super.key,
    required this.words,
    required this.performance,
  });

  final List<ReadingWord> words;
  final Map<String, int> performance;

  @override
  State<ReadingListPage> createState() => _ReadingListPageState();
}

class _ReadingListPageState extends State<ReadingListPage>
    with AutomaticKeepAliveClientMixin {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Widget _buildWordCard(ReadingWord word, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ScoreBox(score: widget.performance[word.key] ?? 0),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.japanese,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    word.romanji,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(word.french, style: const TextStyle(fontSize: 17)),
                  if (word.context.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.context,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Écouter',
              icon: const Icon(Icons.volume_up),
              onPressed: () => _tts.speak(word.japanese),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final query = _searchQuery.toLowerCase().trim();
    final filtered = query.isEmpty
        ? widget.words
        : widget.words.where(
            (w) =>
                w.french.toLowerCase().contains(query) ||
                w.romanji.toLowerCase().contains(query) ||
                w.japanese.contains(query),
          );

    final grouped = <String, List<ReadingWord>>{};
    for (final word in filtered) {
      grouped.putIfAbsent(word.category, () => []).add(word);
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un mot...',
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
          Expanded(
            child: grouped.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun mot trouvé.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        for (final word in entry.value)
                          _buildWordCard(word, theme),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
