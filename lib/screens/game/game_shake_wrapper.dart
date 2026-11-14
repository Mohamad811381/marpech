import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

class GameShakeWrapper extends StatelessWidget {
  final AnimationController controller;
  final double Function() intensity;
  final Widget child;

  const GameShakeWrapper({
    super.key,
    required this.controller,
    required this.intensity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, c) {
        final p = controller.value;
        if (p >= 1.0) return c!;
        final env = (1 - p) * (1 - p) * intensity();
        final maxAmp = 9.0 * env;
        if (maxAmp < 0.3) return c!;
        final dx = math.sin(p * math.pi * 2 * 7) * maxAmp;
        final dy = math.cos(p * math.pi * 2 * 9) * maxAmp * 0.85;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: c,
        );
      },
      child: child,
    );
  }
}