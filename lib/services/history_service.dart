import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_history_entry.dart';

class HistoryService {
  static const _key = 'game_history';
  static const int _maxEntries = 20;

  static Future<void> add(GameHistoryEntry entry) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    final list = <GameHistoryEntry>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        for (final j in decoded) {
          list.add(GameHistoryEntry.fromJson(j as Map<String, dynamic>));
        }
      } catch (_) {
        // ignore corrupted history
      }
    }
    list.insert(0, entry); // جدیدترین اول
    while (list.length > _maxEntries) {
      list.removeLast();
    }
    await p.setString(
      _key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<GameHistoryEntry>> getAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((j) => GameHistoryEntry.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
