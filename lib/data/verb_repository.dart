import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/verb.dart';

class VerbRepository {
  static Future<List<Verb>> loadVerbs() async {
    final jsonString = await rootBundle.loadString('assets/verbs.json');
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return data.entries
        .map((e) => Verb.fromJson(e.key, e.value as Map<String, dynamic>))
        .toList();
  }
}
