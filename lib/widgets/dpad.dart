// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/game_palette.dart';

enum _Dir { up, down, left, right }

class DPad extends StatefulWidget {
  final GamePalette palette;
  final void Function(Point<int>) onDirection;
  final double size;

  const DPad({
    super.key,
    required this.palette,
    required this.onDirection,
    this.size = 210,
  });

  @override
  State<DPad> createState() => _DPadState();
}

class _DPadState extends State<DPad> {
  static const Duration _minHighlight = Duration(milliseconds: 120);
  static const Duration _animDuration = Duration(milliseconds: 100);

  _Dir? _pressed;
  DateTime? _pressedAt;
  Timer? _releaseTimer;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  double get _deadZone => widget.size * 0.085;

  _Dir? _dirFromLocal(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = local - center;

    if (delta.distance < _deadZone) return null;

    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? _Dir.right : _Dir.left;
    }
    return delta.dy > 0 ? _Dir.down : _Dir.up;
  }

  Point<int> _pointOf(_Dir dir) {
    if (dir == _Dir.up) return const Point(0, -1);
    if (dir == _Dir.down) return const Point(0, 1);
    if (dir == _Dir.left) return const Point(-1, 0);
    return const Point(1, 0);
  }

  void _onPointerDown(PointerDownEvent e) {
    final dir = _dirFromLocal(e.localPosition);
    if (dir == null) return;

    _releaseTimer?.cancel();
    setState(() {
      _pressed = dir;
      _pressedAt = DateTime.now();
    });
    widget.onDirection(_pointOf(dir));
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_pressed == null || _pressedAt == null) return;

    final elapsed = DateTime.now().difference(_pressedAt!);
    final remaining = _minHighlight - elapsed;

    _releaseTimer?.cancel();
    if (remaining <= Duration.zero) {
      _clearHighlight();
    } else {
      _releaseTimer = Timer(remaining, _clearHighlight);
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _releaseTimer?.cancel();
    _clearHighlight();
  }

  void _clearHighlight() {
    if (!mounted) return;
    setState(() {
      _pressed = null;
      _pressedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final btnSize = size * 0.276;
    final iconSize = size * 0.143;
    final centerDot = size * 0.105;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _visualButton(
              Alignment.topCenter,
              _Dir.up,
              Icons.keyboard_arrow_up_rounded,
              btnSize,
              iconSize,
            ),
            _visualButton(
              Alignment.bottomCenter,
              _Dir.down,
              Icons.keyboard_arrow_down_rounded,
              btnSize,
              iconSize,
            ),
            _visualButton(
              Alignment.centerLeft,
              _Dir.left,
              Icons.keyboard_arrow_left_rounded,
              btnSize,
              iconSize,
            ),
            _visualButton(
              Alignment.centerRight,
              _Dir.right,
              Icons.keyboard_arrow_right_rounded,
              btnSize,
              iconSize,
            ),
            Container(
              width: centerDot,
              height: centerDot,
              decoration: BoxDecoration(
                color: widget.palette.surface,
                shape: BoxShape.circle,
                border: Border.all(color: widget.palette.border),
              ),
              child: Icon(
                Icons.circle,
                color: widget.palette.border,
                size: centerDot * 0.36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visualButton(
    Alignment align,
    _Dir dir,
    IconData icon,
    double btnSize,
    double iconSize,
  ) {
    final p = widget.palette;
    final pressed = _pressed == dir;

    return Align(
      alignment: align,
      child: AnimatedScale(
        scale: pressed ? 0.92 : 1.0,
        duration: _animDuration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: _animDuration,
          curve: Curves.easeOut,
          width: btnSize,
          height: btnSize,
          decoration: BoxDecoration(
            color: pressed ? p.accent.withAlpha(51) : p.surface,
            borderRadius: BorderRadius.circular(btnSize * 0.31),
            border: Border.all(
              color: pressed ? p.accent : p.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(pressed ? 20 : 64),
                blurRadius: pressed ? 1 : 6,
                offset: pressed ? const Offset(0, 1) : const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: p.accent, size: iconSize),
        ),
      ),
    );
  }
}
