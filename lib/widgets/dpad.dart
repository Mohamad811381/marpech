import 'dart:math';
import 'package:material_ui/material_ui.dart';
import '../models/game_palette.dart';

class DPad extends StatelessWidget {
  final GamePalette palette;
  final void Function(Point<int>) onDirection;
  final double size;

  const DPad({
    super.key,
    required this.palette,
    required this.onDirection,
    this.size = 210,
  });

  double get _deadZone => size * 0.085;

  void _handleTap(Offset local) {
    final center = Offset(size / 2, size / 2);
    final delta = local - center;

    if (delta.distance < _deadZone) return;

    if (delta.dx.abs() > delta.dy.abs()) {
      onDirection(Point(delta.dx > 0 ? 1 : -1, 0));
    } else {
      onDirection(Point(0, delta.dy > 0 ? 1 : -1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final btnSize = size * 0.276;
    final iconSize = size * 0.143;
    final centerDot = size * 0.105;

    // 🔑 Listener جای GestureDetector — پاسخ فوری بدون تأخیر
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _handleTap(e.localPosition),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _visualButton(
              Alignment.topCenter,
              Icons.keyboard_arrow_up_rounded,
              btnSize,
              iconSize,
            ),
            _visualButton(
              Alignment.bottomCenter,
              Icons.keyboard_arrow_down_rounded,
              btnSize,
              iconSize,
            ),
            _visualButton(
              Alignment.centerLeft,
              Icons.keyboard_arrow_left_rounded,
              btnSize,
              iconSize,
            ),
            _visualButton(
              Alignment.centerRight,
              Icons.keyboard_arrow_right_rounded,
              btnSize,
              iconSize,
            ),
            Container(
              width: centerDot,
              height: centerDot,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
              ),
              child: Icon(Icons.circle,
                  color: palette.border, size: centerDot * 0.36),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visualButton(
      Alignment align, IconData icon, double btnSize, double iconSize) {
    return Align(
      alignment: align,
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(btnSize * 0.31),
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, color: palette.accent, size: iconSize),
      ),
    );
  }
}
