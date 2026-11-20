// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:marpech/models/game_palette.dart';




class ModeCard extends StatefulWidget {
  final GamePalette palette;
  final String lottieAsset;
  final String title;
  final String tag;
  final int record;
  final String recordLabel;
  final double letterSpacing;
  final bool animationsEnabled;
  final VoidCallback onTap;

  const ModeCard({super.key, 
    required this.palette,
    required this.lottieAsset,
    required this.title,
    required this.tag,
    required this.record,
    required this.recordLabel,
    required this.letterSpacing,
    required this.animationsEnabled,
    required this.onTap,
  });

  @override
  State<ModeCard> createState() => ModeCardState();
}

class ModeCardState extends State<ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieCtrl;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _lottieCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _lottieCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleIconTap() async {
    if (_playing) return;

    if (widget.animationsEnabled) {
      setState(() => _playing = true);
      try {
        await _lottieCtrl.forward(from: 0);
      } finally {
        if (mounted) setState(() => _playing = false);
      }
      if (!mounted) return;
    }

    widget.onTap();
  }

  void _handleBoxTap() => widget.onTap();

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;

    return InkWell(
      onTap: _handleBoxTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.accent.withOpacity(0.25),
              p.surface,
            ],
          ),
          border: Border.all(color: p.accent.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: p.accent.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize =
                (constraints.maxWidth * 0.5).roundToDouble().clamp(48.0, 68.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleIconTap,
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: iconSize * 0.8,
                              height: iconSize * 0.8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.accent.withOpacity(0.15),
                              ),
                            ),
                            if (widget.animationsEnabled)
                              OverflowBox(
                                maxWidth: iconSize * 1.05,
                                maxHeight: iconSize * 1.05,
                                child: Lottie.asset(
                                  widget.lottieAsset,
                                  controller: _lottieCtrl,
                                  fit: BoxFit.contain,
                                  onLoaded: (comp) {
                                    // ⚡ سریع‌تر از حالت عادی
                                    _lottieCtrl.duration = comp.duration * 0.7;
                                  },
                                ),
                              )
                            else
                              Icon(
                                Icons.play_arrow_rounded,
                                color: p.accent,
                                size: iconSize * 0.45,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: p.accent.withOpacity(0.15),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.tag,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: widget.letterSpacing,
                                color: p.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 18,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: widget.letterSpacing,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: SizedBox(
                        height: 24,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            '${widget.record}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: SizedBox(
                        height: 12,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.recordLabel,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: widget.letterSpacing * 1.2,
                              color: p.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
