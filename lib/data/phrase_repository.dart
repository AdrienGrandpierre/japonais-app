import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/phrase.dart';

class PhraseRepository {
  static Future<List<Phrase>> loadPhrases() async {
    final jsonString = await rootBundle.loadString('assets/phrases.json');
    final data = jsonDecode(jsonString) as List<dynamic>;
    return data
        .map((item) => Phrase.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
