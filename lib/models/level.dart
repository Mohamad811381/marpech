import 'dart:math';
import '../services/localization_service.dart';
import 'portal.dart';

class Level {
  final int id;
  final String emoji;
  final Set<Point<int>> walls;
  final List<PortalPair> portals;
  final int targetFoods;
  final Point<int> snakeStart;
  final Point<int> snakeDir;

  /// ⏱️ محدودیت زمانی — اگه مقدار داشته باشه، مرحله زمان‌داره
  final Duration? timeLimit;
  final Duration tick;


  /// 🔁 عبور از لبه — برای فصل ۴ غیرفعاله
  final bool wrapEnabled;

  Level({
    required this.id,
    required this.emoji,
    required this.walls,
    required this.targetFoods,
    this.portals = const [],
    this.snakeStart = const Point(9, 10),
    this.snakeDir = const Point(0, -1),
    this.timeLimit,
    this.wrapEnabled = true,
      this.tick = const Duration(milliseconds: 140),

  });

  String get name => L10n.t('level_${id}_name');

  /// آیا این مرحله زمان‌داره؟
  bool get isTimed => timeLimit != null;
}

