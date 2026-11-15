// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/game_palette.dart';

/// نوار شیک و مدرن بالای اپ برای اعلام نسخه‌ی جدید.
class UpdateBanner extends StatefulWidget {
  final VoidCallback onUpdate;
  final String message;
  final String subtitle;
  final String buttonLabel;

  const UpdateBanner({
    super.key,
    required this.onUpdate,
    this.message = 'نسخه جدید در دسترس است',
    this.subtitle = 'برای دریافت آخرین امکانات، به‌روزرسانی کنید',
    this.buttonLabel = 'به‌روزرسانی',
  });

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = neonPalette.accent;
    final accentDark = Color.lerp(accent, Colors.black, 0.42)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.2, end: 0.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) =>
          FractionalTranslation(translation: Offset(0, value), child: child),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accentDark],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -20,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) {
                              final v = _pulse.value;
                              return Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white
                                          .withOpacity(0.38 * v),
                                      blurRadius: 22 * v,
                                      spreadRadius: 3 * v,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.rocket_launch_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: widget.onUpdate,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                child: Text(
                                  widget.buttonLabel,
                                  style: TextStyle(
                                    color: accentDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}