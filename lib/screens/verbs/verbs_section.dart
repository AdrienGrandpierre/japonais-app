import 'package:flutter/material.dart';

import '../../data/verb_repository.dart';
import '../../enums/quiz_mode.dart';
import '../../models/verb.dart';
import 'verb_quiz_page.dart';

class VerbsSection extends StatefulWidget {
  const VerbsSection({super.key});

  @override
  State<VerbsSection> createState() => _VerbsSectionState();
}

class _VerbsSectionState extends State<VerbsSection> {
  List<Verb>? _verbs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final verbs = await VerbRepository.loadVerbs();
    if (mounted) setState(() => _verbs = verbs);
  }

  @override
  Widget build(BuildContext context) {
    final verbs = _verbs;
    return DefaultTabController(
      length: VerbDifficulty.values.length,
      initialIndex: VerbDifficulty.normal.index,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verbes'),
          bottom: TabBar(
            tabs: [for (final d in VerbDifficulty.values) Tab(text: d.label)],
          ),
        ),
        body: verbs == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  for (final d in VerbDifficulty.values)
                    VerbQuizPage(verbs: verbs, difficulty: d),
                ],
              ),
      ),
    );
  }
}
