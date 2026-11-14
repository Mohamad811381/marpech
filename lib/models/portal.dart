import 'dart:math';
import 'package:material_ui/material_ui.dart';

class PortalColors {
  static const cyan = Color(0xFF00E5FF);
  static const purple = Color(0xFF7C4DFF);
  static const green = Color(0xFF00E676);
  static const gold = Color(0xFFFFD700);
}

class PortalPair {
  final Point<int> a;
  final Point<int> b;
  final Color color;

  const PortalPair({
    required this.a,
    required this.b,
    required this.color,
  });

  /// اگه pos یکی از دو دروازه باشه، اون یکی رو برمی‌گردونه
  Point<int>? destination(Point<int> pos) {
    if (pos == a) return b;
    if (pos == b) return a;
    return null;
  }

  bool contains(Point<int> pos) => pos == a || pos == b;
}