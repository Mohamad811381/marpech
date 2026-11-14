import 'package:shared_preferences/shared_preferences.dart';
import '../models/difficulty.dart';

/// ضبط یک بازی: هر tick = (headX, headY, snakeLength) در یک int بسته‌بندی شده
class GhostRecording {
  /// هر entry = ((length & 0x3FF) << 10) | ((y & 0x1F) << 5) | (x & 0x1F)
  final List<int> ticks;

  const GhostRecording(this.ticks);

  int get totalTicks => ticks.length;

  int? _decodeLength(int tick) {
    if (tick < 0 || tick >= ticks.length) return null;
    return (ticks[tick] >> 10) & 0x3FF;
  }

  ({int x, int y})? _decodePos(int tick) {
    if (tick < 0 || tick >= ticks.length) return null;
    final v = ticks[tick];
    return (x: v & 0x1F, y: (v >> 5) & 0x1F);
  }

  /// بدنه‌ی شبح در یک tick مشخص، از سر به دم
  List<({int x, int y})> bodyAt(int tick) {
    final len = _decodeLength(tick);
    if (len == null || len <= 0) return const [];
    final start = tick - len + 1;
    final body = <({int x, int y})>[];
    for (var i = start; i <= tick; i++) {
      final p = _decodePos(i);
      if (p != null) body.add(p);
    }
    return body.reversed.toList();
  }

  static int encode({required int x, required int y, required int length}) {
    return ((length & 0x3FF) << 10) | ((y & 0x1F) << 5) | (x & 0x1F);
  }
}

class GhostService {
  static const _prefix = 'ghost_';

  static String _keyFor(Difficulty d, bool timeAttack) {
    if (timeAttack) return '${_prefix}time_attack';
    return '${_prefix}free_${d.name}';
  }

  static Future<void> save({
    required Difficulty difficulty,
    required bool timeAttack,
    required List<int> ticks,
  }) async {
    if (ticks.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    // سقف ۵۰۰۰ tick (~۲۵KB) برای جلوگیری از حجیم شدن
    final trimmed =
        ticks.length > 5000 ? ticks.sublist(ticks.length - 5000) : ticks;
    await p.setString(_keyFor(difficulty, timeAttack), trimmed.join(','));
  }

  static Future<GhostRecording?> load({
    required Difficulty difficulty,
    required bool timeAttack,
  }) async {
    final p = await SharedPreferences.getInstance();
    final data = p.getString(_keyFor(difficulty, timeAttack));
    if (data == null || data.isEmpty) return null;
    final parsed = <int>[];
    for (final s in data.split(',')) {
      final v = int.tryParse(s);
      if (v != null) parsed.add(v);
    }
    if (parsed.isEmpty) return null;
    return GhostRecording(parsed);
  }

  static Future<void> clear({
    required Difficulty difficulty,
    required bool timeAttack,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyFor(difficulty, timeAttack));
  }
}
