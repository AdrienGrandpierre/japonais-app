import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/phrase.dart';

class PhraseRepository {
  static Future<List<Phrase>> loadPhrases() async {
    final jsonString = await rootBundle.loadString('assets/phrases.json');
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final phrases = <Phrase>[];

    for (final entry in data.entries) {
      final category = entry.key;
      final items = entry.value as List<dynamic>;
      for (final item in items) {
        phrases.add(
          Phrase.fromJson(item as Map<String, dynamic>, category: category),
        );
      }
    }

    return phrases;
  }
}
