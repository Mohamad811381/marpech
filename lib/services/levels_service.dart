// ignore_for_file: prefer_const_constructors

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level.dart';
import 'package:material_ui/material_ui.dart';
import '../models/chapter.dart';
import '../models/portal.dart';

class LevelsService {
  static const _progressKey = 'levels_progress';
  static const _completedKey = 'levels_completed';

  static List<Level>? _cache;
  static List<Level> get all => _cache ??= _buildLevels();
  static const List<Chapter> chapters = [
    Chapter(
      id: 1,
      emoji: '🟢',
      accentColor: Color(0xFF4CE0B3),
      startLevelId: 1,
      endLevelId: 10,
    ),
    Chapter(
      id: 2,
      emoji: '🟡',
      accentColor: Color(0xFFFF8A5B),
      startLevelId: 11,
      endLevelId: 20,
    ),
    Chapter(
      id: 3,
      emoji: '🟣',
      accentColor: Color(0xFF7C4DFF),
      startLevelId: 21,
      endLevelId: 30,
    ),
    Chapter(
      id: 4,
      emoji: '🔴',
      accentColor: Color(0xFFFF3D3D),
      startLevelId: 31,
      endLevelId: 40,
    ),
  ];

  static Chapter? getChapter(int id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Level> levelsOfChapter(Chapter chapter) {
    return all
        .where(
            (l) => l.id >= chapter.startLevelId && l.id <= chapter.endLevelId)
        .toList();
  }

  static bool isChapterAvailable(Chapter chapter) {
    return all
        .any((l) => l.id >= chapter.startLevelId && l.id <= chapter.endLevelId);
  }

  static List<Point<int>> _box(int x1, int y1, int x2, int y2) {
    final r = <Point<int>>[];
    for (var y = y1; y <= y2; y++) {
      for (var x = x1; x <= x2; x++) {
        r.add(Point(x, y));
      }
    }
    return r;
  }

  static List<Point<int>> _border() {
    final r = <Point<int>>[];
    for (var x = 0; x < 20; x++) {
      r.add(Point(x, 0));
      r.add(Point(x, 19));
    }
    for (var y = 1; y < 19; y++) {
      r.add(Point(0, y));
      r.add(Point(19, y));
    }
    return r;
  }

  static List<Level> _buildLevels() {
    return [
      // ============================================
      // 🟢 ۱-۱۰ (بدون دیوار کناری)
      // ============================================

      // ۱. گوشه‌ها
      Level(
        id: 1,
        emoji: '🚀',
        targetFoods: 5,
        walls: {
          ..._box(2, 2, 3, 3),
          ..._box(16, 2, 17, 3),
          ..._box(2, 16, 3, 17),
          ..._box(16, 16, 17, 17),
        },
      ),

      // ۲. صلیب
      Level(
        id: 2,
        emoji: '➕',
        targetFoods: 6,
        walls: {
          ..._box(11, 9, 18, 10),
          ..._box(13, 5, 14, 14),
        },
      ),

      // ۳. راهرو
      Level(
        id: 3,
        emoji: '🚪',
        targetFoods: 7, // 4 → 5
        walls: {
          for (var y = 2; y <= 17; y++)
            if (y != 8) Point(6, y),
          for (var y = 2; y <= 17; y++)
            if (y != 14) Point(13, y),
        },
      ),

      // ۴. اتاق
      Level(
        id: 4,
        emoji: '🏠',
        targetFoods: 8, // 4 → 6
        walls: {
          for (var x = 6; x <= 13; x++) Point(x, 6),
          for (var x = 6; x <= 13; x++)
            if (x != 9 && x != 10) Point(x, 12),
          for (var y = 7; y <= 11; y++) Point(6, y),
          for (var y = 7; y <= 11; y++) Point(13, y),
        },
      ),

      // ۵. زیگزاگ
      Level(
        id: 5,
        emoji: '⚡',
        targetFoods: 8, // 4 → 6
        walls: {
          for (var x = 2; x <= 7; x++) Point(x, 7),
          for (var x = 12; x <= 17; x++) Point(x, 7),
          for (var x = 2; x <= 7; x++) Point(x, 13),
          for (var x = 12; x <= 17; x++) Point(x, 13),
        },
      ),

      // ۶. حلقه
      Level(
        id: 6,
        emoji: '⭕',
        targetFoods: 7, // 4 → 5
        walls: {
          for (var x = 6; x <= 13; x++)
            if (x < 9 || x > 10) Point(x, 6),
          for (var x = 6; x <= 13; x++)
            if (x < 9 || x > 10) Point(x, 13),
          for (var y = 7; y <= 12; y++)
            if (y < 9 || y > 10) Point(6, y),
          for (var y = 7; y <= 12; y++)
            if (y < 9 || y > 10) Point(13, y),
        },
      ),

      // ۷. میدان
      Level(
        id: 7,
        emoji: '🏛️',
        targetFoods: 10, // 5 → 8
        walls: {
          ..._box(7, 5, 10, 8),
          ..._box(2, 9, 3, 10),
          ..._box(16, 9, 17, 10),
        },
      ),

      // ۸. هزارتو
      Level(
        id: 8,
        emoji: '🌀',
        targetFoods: 10, // 5 → 8
        walls: {
          for (var y = 2; y <= 17; y++)
            if (y < 9 || y > 11) Point(6, y),
          for (var y = 2; y <= 17; y++)
            if (y < 9 || y > 11) Point(13, y),
          for (var x = 2; x <= 4; x++) Point(x, 10),
          for (var x = 15; x <= 17; x++) Point(x, 10),
        },
      ),

      // ۹. ستون‌ها
      Level(
        id: 9,
        emoji: '🏗️',
        targetFoods: 9, // 5 → 7
        walls: {
          ..._box(2, 2, 3, 3),
          ..._box(8, 2, 9, 3),
          ..._box(14, 2, 15, 3),
          ..._box(2, 8, 3, 9),
          ..._box(14, 8, 15, 9),
          ..._box(2, 14, 3, 15),
          ..._box(8, 14, 9, 15),
          ..._box(14, 14, 15, 15),
        },
      ),

      // ۱۰. نهایی
      Level(
        id: 10,
        emoji: '👑',
        targetFoods: 10, // 6 → 8
        walls: {
          for (var y = 4; y <= 8; y++) Point(5, y),
          for (var x = 3; x <= 7; x++) Point(x, 6),
          for (var y = 4; y <= 8; y++) Point(14, y),
          for (var x = 12; x <= 16; x++) Point(x, 6),
          for (var y = 11; y <= 15; y++) Point(5, y),
          for (var x = 3; x <= 7; x++) Point(x, 13),
          for (var y = 11; y <= 15; y++) Point(14, y),
          for (var x = 12; x <= 16; x++) Point(x, 13),
        },
      ),
      // ============================================
      // 🔴 ۱۱-۲۰ (با دیوار کناری)
      // ============================================

      // ۱۱. قلعه
      Level(
        id: 11,
        emoji: '🏰',
        targetFoods: 7,
        walls: {
          ..._border(),
        },
      ),

      // ۱۲. پل
      Level(
        id: 12,
        emoji: '🌉',
        targetFoods: 7,
        walls: {
          ..._border(),
          for (var x = 2; x <= 17; x++)
            if (x != 9 && x != 10) Point(x, 9),
        },
      ),

      // ۱۳. چهار برج
      Level(
        id: 13,
        emoji: '🏯',
        targetFoods: 8,
        walls: {
          ..._border(),
          ..._box(3, 3, 4, 4),
          ..._box(15, 3, 16, 4),
          ..._box(3, 15, 4, 16),
          ..._box(15, 15, 16, 16),
        },
      ),

      // ۱۴. شبکه — ✅ اصلاح شد (شکاف‌دار)
      Level(
        id: 14,
        emoji: '🕸️',
        targetFoods: 8,
        walls: {
          ..._border(),
          // خط افقی y=6 با شکاف در وسط
          for (var x = 3; x <= 16; x++)
            if (x != 9 && x != 10) Point(x, 6),
          // خط افقی y=13 با شکاف در وسط
          for (var x = 3; x <= 16; x++)
            if (x != 9 && x != 10) Point(x, 13),
          // خط عمودی x=6 با شکاف در وسط
          for (var y = 3; y <= 16; y++)
            if (y != 9 && y != 10) Point(6, y),
          // خط عمودی x=13 با شکاف در وسط
          for (var y = 3; y <= 16; y++)
            if (y != 9 && y != 10) Point(13, y),
        },
      ),

      // ۱۵. حلقه محاصره
      Level(
        id: 15,
        emoji: '🎯',
        targetFoods: 9,
        walls: {
          ..._border(),
          for (var x = 4; x <= 15; x++)
            if (x != 9 && x != 10) Point(x, 4),
          for (var x = 4; x <= 15; x++)
            if (x != 9 && x != 10) Point(x, 15),
          for (var y = 5; y <= 14; y++)
            if (y != 9 && y != 10) Point(4, y),
          for (var y = 5; y <= 14; y++)
            if (y != 9 && y != 10) Point(15, y),
        },
      ),

      // ۱۶. زیگزاگ دوگانه
      Level(
        id: 16,
        emoji: '⚡',
        targetFoods: 9,
        walls: {
          ..._border(),
          for (var x = 3; x <= 7; x++) Point(x, 6),
          for (var x = 12; x <= 16; x++) Point(x, 6),
          for (var x = 3; x <= 7; x++) Point(x, 13),
          for (var x = 12; x <= 16; x++) Point(x, 13),
        },
      ),

      // ۱۷. دو ستون
      Level(
        id: 17,
        emoji: '🏛️',
        targetFoods: 9,
        walls: {
          ..._border(),
          for (var y = 3; y <= 16; y++) Point(6, y),
          for (var y = 3; y <= 16; y++) Point(13, y),
        },
      ),

      // ۱۸. دو اتاق
      Level(
        id: 18,
        emoji: '🚪',
        targetFoods: 10,
        walls: {
          ..._border(),
          for (var y = 2; y <= 8; y++) Point(6, y),
          for (var y = 14; y <= 17; y++) Point(6, y),
          for (var y = 2; y <= 8; y++) Point(13, y),
          for (var y = 14; y <= 17; y++) Point(13, y),
        },
      ),

      // ۱۹. ستون‌های متراکم
      Level(
        id: 19,
        emoji: '🏗️',
        targetFoods: 11,
        walls: {
          ..._border(),
          ..._box(3, 3, 4, 4),
          ..._box(7, 3, 8, 4),
          ..._box(12, 3, 13, 4),
          ..._box(16, 3, 17, 4),
          ..._box(3, 8, 4, 9),
          ..._box(7, 8, 8, 9),
          ..._box(12, 8, 13, 9),
          ..._box(16, 8, 17, 9),
          ..._box(3, 13, 4, 14),
          ..._box(7, 13, 8, 14),
          ..._box(12, 13, 13, 14),
          ..._box(16, 13, 17, 14),
          ..._box(9, 14, 10, 15),
        },
      ),

      // ۲۰. قهرمان
      Level(
        id: 20,
        emoji: '👑',
        targetFoods: 12,
        walls: {
          ..._border(),
          ..._box(3, 3, 5, 5),
          ..._box(14, 3, 16, 5),
          ..._box(3, 14, 5, 16),
          ..._box(14, 14, 16, 16),
          ..._box(9, 5, 10, 6),
          ..._box(9, 14, 10, 15),
          ..._box(3, 9, 4, 10),
          ..._box(16, 9, 17, 10),
        },
      ),
      // ============================================
      // 🟣 ۲۱-۳۰ (فصل دروازه‌ها)
      // ============================================

      // ۲۱. اولین پرش — بدون دیوار کناری، wrap فعال
      Level(
        id: 21,
        emoji: '🌀',
        targetFoods: 8,
        walls: const {},
        portals: [
          PortalPair(
            a: const Point(4, 10),
            b: const Point(15, 10),
            color: PortalColors.cyan,
          ),
        ],
      ),

      // ۲۲. دروازه‌ی گوشه — دیوار کناری
      Level(
        id: 22,
        emoji: '🔮',
        targetFoods: 9,
        walls: {
          ..._border(),
        },
        portals: [
          PortalPair(
            a: const Point(2, 2),
            b: const Point(17, 17),
            color: PortalColors.cyan,
          ),
        ],
      ),

      // ۲۳. پرش عمودی — دروازه بالا/پایین
      Level(
        id: 23,
        emoji: '🌐',
        targetFoods: 9,
        walls: {
          ..._border(),
        },
        portals: [
          PortalPair(
            a: const Point(9, 3),
            b: const Point(9, 16),
            color: PortalColors.purple,
          ),
        ],
      ),

      // ۲۴. دو مسیر — ۲ جفت دروازه افقی
      Level(
        id: 24,
        emoji: '🔀',
        targetFoods: 10,
        walls: {
          ..._border(),
        },
        portals: [
          PortalPair(
            a: const Point(2, 4),
            b: const Point(17, 4),
            color: PortalColors.cyan,
          ),
          PortalPair(
            a: const Point(2, 15),
            b: const Point(17, 15),
            color: PortalColors.purple,
          ),
        ],
      ),

      // ۲۵. چهار برج — گوشه‌ها + ۲ جفت
      Level(
        id: 25,
        emoji: '🏯',
        targetFoods: 11,
        walls: {
          ..._border(),
          ..._box(4, 4, 5, 5),
          ..._box(14, 4, 15, 5),
          ..._box(4, 14, 5, 15),
          ..._box(14, 14, 15, 15),
        },
        portals: [
          PortalPair(
            a: const Point(9, 2),
            b: const Point(9, 17),
            color: PortalColors.cyan,
          ),
          PortalPair(
            a: const Point(2, 9),
            b: const Point(17, 9),
            color: PortalColors.purple,
          ),
        ],
      ),

      // ۲۶. ستون میانی — ستون وسط + ۲ جفت
      Level(
        id: 26,
        emoji: '🎯',
        targetFoods: 11,
        snakeStart: const Point(5, 10),
        snakeDir: const Point(0, -1),
        walls: {
          ..._border(),
          ..._box(9, 9, 10, 10),
        },
        portals: [
          PortalPair(
            a: const Point(3, 10),
            b: const Point(16, 10),
            color: PortalColors.cyan,
          ),
          PortalPair(
            a: const Point(10, 4),
            b: const Point(10, 15),
            color: PortalColors.purple,
          ),
        ],
      ),

      // ۲۷. سه دروازه — ۲ ستون + ۳ جفت
      Level(
        id: 27,
        emoji: '🌟',
        targetFoods: 12,
        walls: {
          ..._border(),
          ..._box(6, 6, 7, 7),
          ..._box(12, 12, 13, 13),
        },
        portals: [
          PortalPair(
            a: const Point(3, 3),
            b: const Point(16, 16),
            color: PortalColors.cyan,
          ),
          PortalPair(
            a: const Point(3, 16),
            b: const Point(16, 3),
            color: PortalColors.purple,
          ),
          PortalPair(
            a: const Point(9, 2),
            b: const Point(9, 17),
            color: PortalColors.green,
          ),
        ],
      ),

      // ۲۸. شبکه‌ی دروازه — دیوارهای نازک + ۳ جفت
      Level(
        id: 28,
        emoji: '🕸️',
        targetFoods: 13,
        walls: {
          ..._border(),
          // خطوط افقی با شکاف
          for (var x = 3; x <= 16; x++)
            if (x != 9 && x != 10) Point(x, 6),
          for (var x = 3; x <= 16; x++)
            if (x != 9 && x != 10) Point(x, 13),
        },
        portals: [
          PortalPair(
            a: const Point(4, 4),
            b: const Point(15, 15),
            color: PortalColors.cyan,
          ),
          PortalPair(
            a: const Point(4, 15),
            b: const Point(15, 4),
            color: PortalColors.purple,
          ),
          PortalPair(
            a: const Point(9, 2),
            b: const Point(9, 17),
            color: PortalColors.green,
          ),
        ],
      ),

      // ۲۹. قصر شیشه‌ای — ۴ گوشه + ستون بالا + ۳ جفت
      Level(
        id: 29,
        emoji: '💎',
        targetFoods: 13,
        walls: {
          ..._border(),
          ..._box(3, 3, 4, 4),
          ..._box(15, 3, 16, 4),
          ..._box(3, 15, 4, 16),
          ..._box(15, 15, 16, 16),
          ..._box(9, 4, 10, 5),
        },
        portals: [
          PortalPair(
            a: const Point(2, 10),
            b: const Point(17, 10),
            color: PortalColors.cyan,
          ),
          PortalPair(
            a: const Point(5, 5),
            b: const Point(14, 14),
            color: PortalColors.purple,
          ),
          PortalPair(
            a: const Point(5, 14),
            b: const Point(14, 5),
            color: PortalColors.green,
          ),
        ],
      ),

      // ۳۰. استاد دروازه — ۴ جفت + ترکیب کامل
      Level(
        id: 30,
        emoji: '👑',
        targetFoods: 15,
        snakeStart: const Point(5, 10),
        snakeDir: const Point(0, -1),
        walls: {
          ..._border(),
          ..._box(3, 3, 4, 4),
          ..._box(15, 3, 16, 4),
          ..._box(3, 15, 4, 16),
          ..._box(15, 15, 16, 16),
          ..._box(9, 6, 10, 7),
          ..._box(9, 12, 10, 13),
        },
        portals: [
          PortalPair(
            a: const Point(2, 5),
            b: const Point(17, 5),
            color: PortalColors.cyan,
          ),
          PortalPair(
            a: const Point(2, 15),
            b: const Point(17, 15),
            color: PortalColors.purple,
          ),
          PortalPair(
            a: const Point(5, 2),
            b: const Point(5, 17),
            color: PortalColors.green,
          ),
          PortalPair(
            a: const Point(15, 2),
            b: const Point(15, 17),
            color: PortalColors.gold,
          ),
        ],
      ),

      // ============================================
      // 🔴 ۳۱-۴۰ (فصل قصر زمان — محدودیت زمانی)
      // ============================================
      // همه‌ی مراحل دیوار کناری دارن (wrapEnabled: false)

      // ۳۱. زنگ خطر — ۲ دیوار افقی با شکاف
      Level(
        id: 31,
        emoji: '⏰',
        targetFoods: 8,
        timeLimit: const Duration(seconds: 120),
        wrapEnabled: false,
        walls: {
          ..._border(),
          // دیوار افقی y=5 با ۲ شکاف
          for (var x = 2; x <= 17; x++)
            if (x != 5 && x != 14) Point(x, 5),
          // دیوار افقی y=14 با ۲ شکاف
          for (var x = 2; x <= 17; x++)
            if (x != 5 && x != 14) Point(x, 14),
        },
      ),
      // ۳۲. فشار — دو دیوار افقی با شکاف وسط
      Level(
        id: 32,
        emoji: '🚧',
        targetFoods: 8,
        timeLimit: const Duration(seconds: 115),
        wrapEnabled: false,
        walls: {
          ..._border(),
          for (var x = 2; x <= 17; x++)
            if (x != 9 && x != 10) Point(x, 6),
          for (var x = 2; x <= 17; x++)
            if (x != 9 && x != 10) Point(x, 13),
        },
      ),

      // ۳۳. راهروها — دو دیوار عمودی با شکاف وسط
      Level(
        id: 33,
        emoji: '🚪',
        targetFoods: 9,
        timeLimit: const Duration(seconds: 110),
        wrapEnabled: false,
        walls: {
          ..._border(),
          for (var y = 2; y <= 17; y++)
            if (y != 9 && y != 10) Point(6, y),
          for (var y = 2; y <= 17; y++)
            if (y != 9 && y != 10) Point(13, y),
        },
      ),

      // ۳۴. چهار برج — ۴ ستون + ۲ دیوار عمودی + ۲ افقی
      Level(
        id: 34,
        emoji: '🏯',
        targetFoods: 9,
        timeLimit: const Duration(seconds: 105),
        wrapEnabled: false,
        walls: {
          ..._border(),
          // ۴ ستون گوشه
          ..._box(2, 2, 3, 3),
          ..._box(16, 2, 17, 3),
          ..._box(2, 16, 3, 17),
          ..._box(16, 16, 17, 17),
          // ۲ دیوار عمودی با شکاف وسط
          for (var y = 4; y <= 15; y++)
            if (y != 9 && y != 10) Point(6, y),
          for (var y = 4; y <= 15; y++)
            if (y != 9 && y != 10) Point(13, y),
          // ۲ دیوار افقی با شکاف وسط (بالا و پایین)
          for (var x = 7; x <= 12; x++)
            if (x != 9 && x != 10) Point(x, 4),
          for (var x = 7; x <= 12; x++)
            if (x != 9 && x != 10) Point(x, 15),
        },
      ),

      // ۳۵. صلیب — دیوارهای عمودی + افقی با شکاف
      // ۳۵. صلیب — دیوارهای عمودی + افقی با شکاف (نسخه آسان‌تر)
      Level(
        id: 35,
        emoji: '➕',
        targetFoods: 10,
        timeLimit: const Duration(seconds: 150),
        wrapEnabled: false,
        tick: const Duration(milliseconds: 160),
        walls: {
          ..._border(),
          // دیوار عمودی x=6 با ۴ شکاف
          for (var y = 2; y <= 17; y++)
            if (y != 4 && y != 9 && y != 10 && y != 15) Point(6, y),
          // دیوار عمودی x=13 با ۴ شکاف
          for (var y = 2; y <= 17; y++)
            if (y != 4 && y != 9 && y != 10 && y != 15) Point(13, y),
          // دیوار افقی y=3 با شکاف بزرگ‌تر در وسط
          for (var x = 2; x <= 17; x++)
            if (x < 8 || x > 11) Point(x, 3),
          // دیوار افقی y=16 با شکاف بزرگ‌تر در وسط
          for (var x = 2; x <= 17; x++)
            if (x < 8 || x > 11) Point(x, 16),
        },
      ),

      // ۳۶. زیگزاگ — مار از غرب شروع می‌کنه، شکاف‌های متناوب چپ-راست-چپ
      Level(
        id: 36,
        emoji: '⚡',
        targetFoods: 12,
        timeLimit: const Duration(seconds: 100),
        wrapEnabled: false,
        walls: {
          ..._border(),

          // ردیف ۱۵ (نزدیک شروع مار از غرب) — دیوار راست، شکاف چپ
          for (var x = 10; x <= 18; x++) Point(x, 15),

          // ردیف ۱۰ (وسط) — دیوار چپ، شکاف راست
          for (var x = 1; x <= 9; x++) Point(x, 10),

          // ردیف ۵ (بالا) — دیوار راست، شکاف چپ
          for (var x = 10; x <= 18; x++) Point(x, 5),
        },
      ),

      // ۳۷. شبکه — آسون‌تر: شکاف‌های ۲ خانه‌ای، دیوارهای کمتر، غذای کمتر
      Level(
        id: 37,
        emoji: '🕸️',
        targetFoods: 10,
        timeLimit: const Duration(seconds: 110),
        wrapEnabled: false,
        walls: {
          ..._border(),

          // دیوارهای عمودی x=5 و x=14 — هر شکاف ۲ خانه‌ای (به‌جای ۱ خانه)
          for (var y = 2; y <= 17; y++)
            if (y != 3 && y != 4 && y != 9 && y != 10 && y != 15 && y != 16)
              Point(5, y),
          for (var y = 2; y <= 17; y++)
            if (y != 3 && y != 4 && y != 9 && y != 10 && y != 15 && y != 16)
              Point(14, y),

          // دیوارهای افقی y=7 و y=13 — شکاف‌های پهن‌تر (۲ و ۴ خانه‌ای)
          for (var x = 2; x <= 17; x++)
            if (x != 3 &&
                x != 4 &&
                x != 8 &&
                x != 9 &&
                x != 10 &&
                x != 11 &&
                x != 14 &&
                x != 15)
              Point(x, 7),
          for (var x = 2; x <= 17; x++)
            if (x != 3 &&
                x != 4 &&
                x != 8 &&
                x != 9 &&
                x != 10 &&
                x != 11 &&
                x != 14 &&
                x != 15)
              Point(x, 13),
        },
      ),

      // ۳۸. حلقه‌ها — دو حلقه‌ی تودرتو با ۴ شکاف
      Level(
        id: 38,
        emoji: '⭕',
        targetFoods: 11,
        timeLimit: const Duration(seconds: 85),
        wrapEnabled: false,
        walls: {
          ..._border(),
          // حلقه‌ی بیرونی با ۴ شکاف
          for (var x = 3; x <= 16; x++)
            if (x != 9 && x != 10) Point(x, 3),
          for (var x = 3; x <= 16; x++)
            if (x != 9 && x != 10) Point(x, 16),
          for (var y = 4; y <= 15; y++)
            if (y != 9 && y != 10) Point(3, y),
          for (var y = 4; y <= 15; y++)
            if (y != 9 && y != 10) Point(16, y),
          // حلقه‌ی داخلی با ۴ شکاف
          for (var x = 7; x <= 12; x++)
            if (x != 9 && x != 10) Point(x, 7),
          for (var x = 7; x <= 12; x++)
            if (x != 9 && x != 10) Point(x, 12),
          for (var y = 8; y <= 11; y++)
            if (y != 9 && y != 10) Point(7, y),
          for (var y = 8; y <= 11; y++)
            if (y != 9 && y != 10) Point(12, y),
        },
      ),

      // ۳۹. قلعه — ۴ اتاق گوشه + هسته‌ی مرکزی با شکاف
      Level(
        id: 39,
        emoji: '🏰',
        targetFoods: 12,
        timeLimit: const Duration(seconds: 75),
        wrapEnabled: false,
        walls: {
          ..._border(),
          // ۴ اتاق گوشه
          ..._box(3, 3, 5, 5),
          ..._box(14, 3, 16, 5),
          ..._box(3, 14, 5, 16),
          ..._box(14, 14, 16, 16),
          // هسته‌ی مرکزی با ۴ شکاف
          for (var y = 7; y <= 12; y++)
            if (y != 9 && y != 10) Point(8, y),
          for (var y = 7; y <= 12; y++)
            if (y != 9 && y != 10) Point(11, y),
          for (var x = 8; x <= 11; x++)
            if (x != 9 && x != 10) Point(x, 8),
          for (var x = 8; x <= 11; x++)
            if (x != 9 && x != 10) Point(x, 11),
        },
      ),

      // ۴۰. استاد زمان — نهایی
      Level(
        id: 40,
        emoji: '👑',
        targetFoods: 12,
        timeLimit: const Duration(seconds: 60),
        wrapEnabled: false,
        walls: {
          ..._border(),
          // ۴ ستون گوشه
          ..._box(3, 3, 4, 4),
          ..._box(15, 3, 16, 4),
          ..._box(3, 15, 4, 16),
          ..._box(15, 15, 16, 16),
          // دیوارهای عمودی x=6, x=13 با شکاف
          for (var y = 5; y <= 14; y++)
            if (y != 9 && y != 10) Point(6, y),
          for (var y = 5; y <= 14; y++)
            if (y != 9 && y != 10) Point(13, y),
          // دیوارهای افقی y=6, y=13 با شکاف
          for (var x = 5; x <= 14; x++)
            if (x != 9 && x != 10) Point(x, 6),
          for (var x = 5; x <= 14; x++)
            if (x != 9 && x != 10) Point(x, 13),
        },
      ),
    ];
  }

  // static Future<int> getHighestUnlocked() async {

  //   final p = await SharedPreferences.getInstance();
  //   return p.getInt(_progressKey) ?? 1;
  // }

  static Future<int> getHighestUnlocked() async {
    return all.length; // 🔓 موقتاً همه‌ی ۴۰ مرحله باز (برای تست)
    // final p = await SharedPreferences.getInstance();
    // return p.getInt(_progressKey) ?? 1;
  }

  static Future<void> unlockNext(int currentId) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_progressKey) ?? 1;
    if (currentId + 1 > current && currentId + 1 <= all.length) {
      await p.setInt(_progressKey, currentId + 1);
    }
  }

  static Future<Set<int>> getCompleted() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_completedKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static Future<void> markCompleted(int levelId) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_completedKey) ?? [];
    if (!list.contains('$levelId')) {
      list.add('$levelId');
      await p.setStringList(_completedKey, list);
    }
  }

  static Future<void> resetProgress() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_progressKey);
    await p.remove(_completedKey);
  }

  static Level? getNext(int currentId) {
    final idx = all.indexWhere((l) => l.id == currentId);
    if (idx == -1 || idx + 1 >= all.length) return null;
    return all[idx + 1];
  }

  static Level? getById(int id) {
    try {
      return all.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}
