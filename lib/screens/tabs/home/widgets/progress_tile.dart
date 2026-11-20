// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:marpech/models/game_palette.dart';

class ProgressTile extends StatefulWidget {
  final GamePalette palette;
  final IconData icon;
  final String value;
  final String label;
  final double iconSize;
  final double letterSpacing;
  final bool animationsEnabled;
  final VoidCallback? onTap;
  final double? progress;
  final bool highlight;
  final String? lottieAsset;

  const ProgressTile({
    super.key,
    required this.palette,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconSize,
    required this.letterSpacing,
    required this.animationsEnabled,
    this.onTap,
    this.progress,
    this.highlight = false,
    this.lottieAsset,
  });

  @override
  State<ProgressTile> createState() => _ProgressTileState();
}

class _ProgressTileState extends State<ProgressTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieCtrl;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _lottieCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // پیش‌فرض تا onLoaded بیاد
    );
  }

  Future<void> _handleIconTap() async {
    if (_playing) return;

    // آیکون → اول انیمیشن، بعد ناوبری
    if (widget.lottieAsset != null && widget.animationsEnabled) {
      setState(() => _playing = true);
      try {
        await _lottieCtrl.forward(from: 0);
      } finally {
        if (mounted) setState(() => _playing = false);
      }
      if (!mounted) return;
    }

    widget.onTap?.call();
  }

  void _handleBoxTap() {
    // باکس → اگه مقصد داره، فوری برو
    if (widget.onTap != null) {
      widget.onTap!.call();
    } else {
      // کاشی XP که مقصد نداره → بازم انیمیشن پخش کن
      _handleIconTap();
    }
  }

  @override
  void dispose() {
    _lottieCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;

    return InkWell(
      onTap: _handleBoxTap, // ← باکس → فوری می‌ره
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.highlight ? p.accent : p.border.withOpacity(0.6),
            width: widget.highlight ? 1.2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── آیکون (GestureDetector جدا) ──
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleIconTap, // ← آیکون → اول انیمیشن
              child: SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: widget.iconSize * 0.8,
                      height: widget.iconSize * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.accent.withOpacity(0.15),
                      ),
                    ),
                    if (widget.lottieAsset != null)
                      OverflowBox(
                        maxWidth: widget.iconSize * 1.05,
                        maxHeight: widget.iconSize * 1.05,
                        child: Lottie.asset(
                          widget.lottieAsset!,
                          controller: _lottieCtrl,
                          fit: BoxFit.contain,
                          onLoaded: (comp) {
                            _lottieCtrl.duration = comp.duration;
                          },
                        ),
                      )
                    else
                      Icon(
                        widget.icon,
                        size: widget.iconSize * 0.45,
                        color: p.accent,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // ── مقدار ──
            SizedBox(
              height: 22,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),

            // ── برچسب ──
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: widget.letterSpacing,
                    color: p.textMuted,
                  ),
                ),
              ),
            ),

            // ── نوار پیشرفت ──
            if (widget.progress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: widget.progress,
                  minHeight: 3,
                  backgroundColor: p.border.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation(p.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
