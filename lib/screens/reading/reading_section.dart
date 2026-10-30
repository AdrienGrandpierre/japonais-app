import 'package:flutter/material.dart';

import '../../models/reading_word.dart';
import 'reading_choice_page.dart';
import 'reading_list_page.dart';
import 'reading_recall_page.dart';

class ReadingSection extends StatelessWidget {
  const ReadingSection({
    super.key,
    required this.words,
    required this.performance,
    required this.onResult,
    required this.onReset,
  });

  final List<ReadingWord> words;
  final Map<String, int> performance;
  final void Function(String key, bool correct) onResult;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lecture'),
          actions: [
            IconButton(
              tooltip: 'Réinitialiser les scores',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                onReset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scores de lecture réinitialisés.'),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Facile'),
              Tab(text: 'Normal'),
              Tab(text: 'Liste'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReadingChoicePage(words: words),
            ReadingRecallPage(
              words: words,
              performance: performance,
              onResult: onResult,
            ),
            ReadingListPage(words: words, performance: performance),
          ],
        ),
      ),
    );
  }
}
