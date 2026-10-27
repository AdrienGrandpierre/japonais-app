import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PerformanceRepository {
  static const _key = 'phrasePerformance';

  static Future<Map<String, int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    final result = <String, int>{};
    if (stored == null) return result;

    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is int) {
            result[entry.key] = value.clamp(-5, 5);
          } else if (value is String) {
            result[entry.key] = int.tryParse(value)?.clamp(-5, 5) ?? 0;
          }
        }
      }
    } catch (_) {
      // Données corrompues : on repart de zéro.
    }
    return result;
  }

  static Future<void> save(Map<String, int> performance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(performance));
  }
}
