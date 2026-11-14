// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VirtualJoystick extends StatefulWidget {
  /// اندازه‌ی کل پد (px)
  final double size;

  /// رنگ پس‌زمینه‌ی پد
  final Color background;

  /// رنگ فلش‌ها و thumb
  final Color foreground;

  /// callback جهت — فقط وقتی تغییر می‌کنه fire می‌شه
  final ValueChanged<Point<int>> onDirection;

  /// فعال/غیرفعال
  final bool enabled;

  /// لرزش هنگام تغییر جهت
  final bool enableHaptics;

  const VirtualJoystick({
    super.key,
    this.size = 170,
    required this.background,
    required this.foreground,
    required this.onDirection,
    this.enabled = true,
    this.enableHaptics = true,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick>
    with SingleTickerProviderStateMixin {
  late AnimationController _snapBackController;

  Offset _thumb = Offset.zero;
  Point<int>? _activeDir;
  Offset _snapFrom = Offset.zero;

  double get _size => widget.size > 0 ? widget.size : 170;
  double get _maxRadius => _size * 0.30;
  double get _deadZone => _maxRadius * 0.32;

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_onSnapTick);
  }

  void _onSnapTick() {
    final t = Curves.easeOutCubic.transform(_snapBackController.value);
    setState(() {
      _thumb = Offset.lerp(_snapFrom, Offset.zero, t) ?? Offset.zero;
    });
  }

  @override
  void didUpdateWidget(covariant VirtualJoystick old) {
    super.didUpdateWidget(old);
    if (old.enabled != widget.enabled && !widget.enabled) {
      _resetToCenter();
    }
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  void _resetToCenter({bool animate = true}) {
    _activeDir = null;
    if (_thumb != Offset.zero) {
      if (animate) {
        _snapFrom = _thumb;
        _snapBackController.forward(from: 0);
      } else {
        setState(() => _thumb = Offset.zero);
      }
    }
  }

  void _handleStart(Offset local) {
    if (!widget.enabled) return;
    _snapBackController.stop();
    final center = Offset(_size / 2, _size / 2);
    final clamped = _clampToMax(local - center);
    setState(() => _thumb = clamped);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact().catchError((_) {});
    }
    _updateDirection(clamped);
  }

  void _handleUpdate(Offset local) {
    if (!widget.enabled) return;
    final center = Offset(_size / 2, _size / 2);
    final clamped = _clampToMax(local - center);
    setState(() => _thumb = clamped);
    _updateDirection(clamped);
  }

  void _handleEnd() {
    if (!widget.enabled) return;
    if (_activeDir != null) {
      _activeDir = null;
      widget.onDirection(const Point(0, 0));
    }
    _snapFrom = _thumb;
    _snapBackController.forward(from: 0);
  }

  Offset _clampToMax(Offset delta) {
    final dist = delta.distance;
    if (dist <= _maxRadius) return delta;
    return delta * (_maxRadius / dist);
  }

  void _updateDirection(Offset thumbOffset) {
    final dist = thumbOffset.distance;
    Point<int> newDir;

    if (dist < _deadZone) {
      newDir = const Point(0, 0);
    } else {
      final dx = thumbOffset.dx;
      final dy = thumbOffset.dy;
      // غالب‌ترین محور — در تساوی، افقی
      if (dx.abs() >= dy.abs()) {
        newDir = Point(dx > 0 ? 1 : -1, 0);
      } else {
        newDir = Point(0, dy > 0 ? 1 : -1);
      }
    }

    final prev = _activeDir ?? const Point(0, 0);
    if (prev != newDir) {
      _activeDir = newDir == const Point(0, 0) ? null : newDir;
      if (widget.enableHaptics && newDir != const Point(0, 0)) {
        HapticFeedback.selectionClick().catchError((_) {});
      }
      widget.onDirection(newDir);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _handleStart(e.localPosition),
      onPointerMove: (e) => _handleUpdate(e.localPosition),
      onPointerUp: (_) => _handleEnd(),
      onPointerCancel: (_) => _handleEnd(),
      child: SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(
          painter: _JoystickPainter(
            size: _size,
            background: widget.background,
            foreground: widget.foreground,
            thumb: _thumb,
            activeDir: _activeDir,
            enabled: widget.enabled,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final double size;
  final Color background;
  final Color foreground;
  final Offset thumb;
  final Point<int>? activeDir;
  final bool enabled;

  _JoystickPainter({
    required this.size,
    required this.background,
    required this.foreground,
    required this.thumb,
    required this.activeDir,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final opacity = enabled ? 1.0 : 0.4;

    // پایه
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = background.withOpacity(opacity),
    );

    // حلقه‌ی بیرونی
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = foreground.withOpacity(0.10 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // فلش‌ها
    _drawArrow(
        canvas, center, -pi / 2, activeDir == const Point(0, -1), opacity);
    _drawArrow(canvas, center, 0, activeDir == const Point(1, 0), opacity);
    _drawArrow(canvas, center, pi / 2, activeDir == const Point(0, 1), opacity);
    _drawArrow(canvas, center, pi, activeDir == const Point(-1, 0), opacity);

    // thumb
    final thumbCenter = center + thumb;
    final thumbRadius = size * 0.18;

    // سایه
    canvas.drawCircle(
      thumbCenter + const Offset(0, 3),
      thumbRadius,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // بدنه
    canvas.drawCircle(
      thumbCenter,
      thumbRadius,
      Paint()..color = foreground.withOpacity(opacity),
    );

    // هایلایت
    canvas.drawCircle(
      thumbCenter + Offset(-thumbRadius * 0.35, -thumbRadius * 0.35),
      thumbRadius * 0.30,
      Paint()..color = Colors.white.withOpacity(0.18 * opacity),
    );
  }

  void _drawArrow(
      Canvas canvas, Offset center, double angle, bool active, double opacity) {
    final distance = size * 0.36;
    final arrowCenter =
        center + Offset(cos(angle) * distance, sin(angle) * distance);
    final h = size * 0.08;
    final w = size * 0.07;

    final tip = arrowCenter + Offset(cos(angle) * h / 2, sin(angle) * h / 2);
    final baseCenter =
        arrowCenter - Offset(cos(angle) * h / 2, sin(angle) * h / 2);
    final perp = Offset(-sin(angle), cos(angle));
    final left = baseCenter + perp * (w / 2);
    final right = baseCenter - perp * (w / 2);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = active
            ? foreground.withOpacity(opacity)
            : foreground.withOpacity(0.22 * opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter old) => true;
}
