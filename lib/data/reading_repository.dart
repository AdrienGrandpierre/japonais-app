import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/reading_word.dart';

class ReadingRepository {
  static Future<List<ReadingWord>> loadWords() async {
    final jsonString = await rootBundle.loadString('assets/reading.json');
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return [
      for (final entry in data.entries)
        for (final item in entry.value as List<dynamic>)
          ReadingWord.fromJson(
            item as Map<String, dynamic>,
            category: entry.key,
          ),
    ];
  }
}
