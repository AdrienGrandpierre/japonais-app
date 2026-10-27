import 'package:flutter/material.dart';

import '../../models/phrase.dart';
import 'phrase_list_page.dart';
import 'phrase_quiz_page.dart';

class PhrasesSection extends StatefulWidget {
  const PhrasesSection({
    super.key,
    required this.phrases,
    required this.performance,
    required this.onResult,
    required this.onReset,
    required this.revisionRequest,
  });

  final List<Phrase> phrases;
  final Map<String, int> performance;
  final void Function(String key, bool correct) onResult;
  final VoidCallback onReset;
  final int revisionRequest;

  @override
  State<PhrasesSection> createState() => _PhrasesSectionState();
}

class _PhrasesSectionState extends State<PhrasesSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void didUpdateWidget(PhrasesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revisionRequest != widget.revisionRequest) {
      _tabController.animateTo(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reset() {
    widget.onReset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scores de quiz réinitialisés.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrases'),
        actions: [
          IconButton(
            tooltip: 'Réinitialiser les scores',
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Quiz'),
            Tab(text: 'Liste'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PhraseQuizPage(
            phrases: widget.phrases,
            performance: widget.performance,
            onResult: widget.onResult,
            revisionRequest: widget.revisionRequest,
          ),
          PhraseListPage(
            phrases: widget.phrases,
            performance: widget.performance,
          ),
        ],
      ),
    );
  }
}
