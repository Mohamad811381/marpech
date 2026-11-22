// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../models/game_palette.dart';
import '../../models/level.dart';
import '../../services/audio_service.dart';
import '../../services/localization_service.dart';

// ─────────────────────────────────────────────────
// Start Countdown Overlay
// ─────────────────────────────────────────────────

class StartCountdownOverlay extends StatelessWidget {
  final GamePalette palette;
  final int countdown;
  final bool showPity;
  final int pityShields;

  const StartCountdownOverlay({
    super.key,
    required this.palette,
    required this.countdown,
    required this.showPity,
    required this.pityShields,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final showGo = countdown <= 0 || countdown == 1;
    final text = showGo ? 'برو!' : '$countdown';
    final color = showGo
        ? p.accent
        : (countdown == 3
            ? p.accent
            : (countdown == 2 ? p.food : const Color(0xFFFF8A5B)));

    return IgnorePointer(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Column(
            key: ValueKey(countdown),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 88,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: p.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  L10n.t('game_get_ready'),
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showPity) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withOpacity(0.3),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: Color(0xFF00F0FF), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        L10n.tf('game_pity_help', {'n': pityShields}),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// End Countdown Overlay
// ─────────────────────────────────────────────────

class EndCountdownOverlay extends StatelessWidget {
  final GamePalette palette;
  final int endCountdown;

  const EndCountdownOverlay({
    super.key,
    required this.palette,
    required this.endCountdown,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final isImpact = endCountdown <= 1;
    final text = isImpact ? '💥' : '$endCountdown';
    final color = isImpact
        ? const Color(0xFFFF3D6A)
        : (endCountdown == 3 ? p.food : const Color(0xFFFF8A5B));

    return IgnorePointer(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: Tween<double>(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Column(
            key: ValueKey(endCountdown),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isImpact)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.food.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.food.withOpacity(0.5)),
                  ),
                  child: Text(
                    L10n.t('game_crashed'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.food,
                    ),
                  ),
                ),
              Text(
                text,
                style: TextStyle(
                  fontSize: isImpact ? 110 : 96,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(0.7),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Game Overlay (win / game over / paused)
// ─────────────────────────────────────────────────

class GameOverlay extends StatelessWidget {
  final GamePalette palette;

  final bool won;
  final bool over;
  final bool paused;
  final bool timedOut;

  final bool isLevelMode;
  final bool isTimeAttack;
  final Level? level;
  final int score;
  final int best;
  final int foodsEaten;
  final bool newRecord;
  final List<Achievement> newAchievements;
  final bool hasNextLevel;
  final int? botScore;

  final VoidCallback onBack;
  final VoidCallback onReset;
  final VoidCallback onTogglePause;
  final VoidCallback onNextLevel;
  final VoidCallback onOpenWinner;

  const GameOverlay({
    super.key,
    required this.palette,
    required this.won,
    required this.over,
    required this.paused,
    required this.timedOut,
    required this.isLevelMode,
    required this.isTimeAttack,
    required this.level,
    required this.score,
    required this.best,
    required this.foodsEaten,
    required this.newRecord,
    required this.newAchievements,
    required this.hasNextLevel,
    this.botScore,
    required this.onBack,
    required this.onReset,
    required this.onTogglePause,
    required this.onNextLevel,
    required this.onOpenWinner,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: Colors.black.withOpacity(0.82),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: won
              ? _winContent()
              : (over ? _gameOverContent() : _pauseContent()),
        ),
      ),
    );
  }

  // ───────── Win ─────────

  List<Widget> _winContent() {
    final p = palette;
    final isFinalLevel = !hasNextLevel;

    return [
      const Text('🎉', style: TextStyle(fontSize: 44)),
      const SizedBox(height: 8),
      Text(
        L10n.t('game_level_complete'),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: p.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        L10n.tf('game_level_info', {
          'n': level?.id ?? '?',
          'name': level?.name ?? '',
        }),
        style: TextStyle(fontSize: 13, color: p.textMuted),
      ),
      const SizedBox(height: 22),
      if (isFinalLevel) ...[
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onOpenWinner,
            icon: Icon(Icons.celebration_rounded, color: p.onPrimary, size: 22),
            label: Text(
              L10n.t('winner_open_button'),
              style: TextStyle(
                color: p.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.food,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pill(L10n.t('back'), onBack,
              filled: false, icon: Icons.arrow_back_rounded),
          if (hasNextLevel) ...[
            const SizedBox(width: 12),
            _pill(L10n.t('game_next_level'), onNextLevel,
                filled: true, icon: Icons.arrow_forward_rounded),
          ],
        ],
      ),
    ];
  }

  // ───────── Game Over ─────────

  List<Widget> _gameOverContent() {
    final p = palette;
    final bot = botScore;
    final title = bot != null
        ? (score > bot
            ? L10n.t('game_bot_win')
            : score < bot
                ? L10n.t('game_bot_lose')
                : L10n.t('game_bot_draw'))
        : (timedOut ? L10n.t('game_time_up') : L10n.t('game_over'));
    final emoji = bot != null
        ? (score > bot ? '🏆' : (score < bot ? '🤖' : '🤝'))
        : (timedOut ? '⏱️' : null);

    return [
      if (emoji != null) ...[
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 6),
      ],
      Text(
        title,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: p.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      if (!isLevelMode && newRecord)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: p.food.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            L10n.t('game_new_record'),
            style: TextStyle(
              color: p.food,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      if (!isLevelMode && newAchievements.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: p.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.accent.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, color: p.accent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    L10n.t('game_new_achievements'),
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...newAchievements.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• ${a.title}',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      Text(
        bot != null
            ? L10n.tf('game_bot_vs_score', {'n': score, 'm': bot})
            : isLevelMode
            ? L10n.tf('game_progress_label', {
                'n': foodsEaten,
                'm': level?.targetFoods ?? 0,
              })
            : isTimeAttack
                ? L10n.tf('game_score_record', {'n': score, 'm': best})
                : L10n.tf('game_score_label', {'n': score}),
        style: TextStyle(fontSize: 14, color: p.textMuted),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pill(
            isLevelMode ? L10n.t('back') : L10n.t('game_exit'),
            onBack,
            filled: false,
            icon: Icons.arrow_back_rounded,
          ),
          const SizedBox(width: 12),
          _pill(
            isLevelMode
                ? L10n.t('retry')
                : isTimeAttack
                    ? L10n.t('again')
                    : L10n.t('new_game'),
            onReset,
            filled: true,
            icon: Icons.play_arrow_rounded,
          ),
        ],
      ),
    ];
  }

  // ───────── Pause ─────────

  List<Widget> _pauseContent() {
    final p = palette;
    return [
      Text(
        L10n.t('game_pause'),
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: p.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        L10n.t('game_pause_sub'),
        style: TextStyle(fontSize: 14, color: p.textMuted),
      ),
      const SizedBox(height: 20),
      _pill(L10n.t('continue_btn'), onTogglePause,
          filled: true, icon: Icons.play_arrow_rounded),
    ];
  }

  // ───────── Helper ─────────

  Widget _pill(String label, VoidCallback onTap,
      {required bool filled, required IconData icon}) {
    final p = palette;
    return Material(
      color: filled ? p.accent : p.surface,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: filled ? p.onPrimary : p.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: filled ? p.onPrimary : p.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Continue Overlay (Bottom Sheet)
// ─────────────────────────────────────────────────

class ContinueOverlay extends StatefulWidget {
  final GamePalette palette;
  final int coins;
  final int cost;
  final VoidCallback onContinue;
  final VoidCallback onDecline;

  const ContinueOverlay({
    super.key,
    required this.palette,
    required this.coins,
    required this.cost,
    required this.onContinue,
    required this.onDecline,
  });

  @override
  State<ContinueOverlay> createState() => _ContinueOverlayState();
}

class _ContinueOverlayState extends State<ContinueOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _timer;
  late final AnimationController _slideIn;
  final _audio = AudioService();
  bool _handled = false;

  bool get _canAfford => widget.coins >= widget.cost;
  int get _after => widget.coins - widget.cost;
  int get _shortage => widget.cost - widget.coins;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _slideIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _timer.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_handled) {
        _handled = true;
        widget.onDecline();
      }
    });
    _slideIn.forward();
    _timer.forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    _slideIn.dispose();
    super.dispose();
  }

  Future<void> _closeWith(VoidCallback cb) async {
    await _slideIn.reverse();
    if (mounted) cb();
  }

  Future<void> _handleContinue() async {
    if (_handled || !_canAfford) return;
    _handled = true;
    _timer.stop();
    await _audio.playSfx(Sfx.button);
    await _closeWith(widget.onContinue);
  }

  Future<void> _handleDecline() async {
    if (_handled) return;
    _handled = true;
    _timer.stop();
    await _audio.playSfx(Sfx.button);
    await _closeWith(widget.onDecline);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final isFa = L10n.isFa;

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _handleDecline,
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _slideIn,
              builder: (_, child) {
                final v = _slideIn.value.clamp(0.0, 1.0);

                final slideT = Curves.easeOutCubic.transform(v);
                final slide = Offset(0, 1 - slideT);

                final fadeT = Curves.easeOut.transform(v);

                final scaleT = Curves.easeOutBack.transform(v);
                final scale = 0.92 + (scaleT * 0.08);

                return FractionalTranslation(
                  translation: slide,
                  child: Opacity(
                    opacity: fadeT,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  ),
                );
              },
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 340,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: p.accent.withOpacity(0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: p.accent.withOpacity(0.2),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _timer,
                              builder: (_, __) {
                                final remaining =
                                    (1.0 - _timer.value).clamp(0.0, 1.0);
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: remaining,
                                    minHeight: 3,
                                    backgroundColor: p.border.withOpacity(0.4),
                                    valueColor: AlwaysStoppedAnimation(
                                      _canAfford ? p.accent : p.food,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _timer,
                                  builder: (_, __) {
                                    final remaining =
                                        (1.0 - _timer.value).clamp(0.0, 1.0);
                                    final secs =
                                        (remaining * 5).ceil().clamp(1, 5);
                                    return Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: p.accent.withOpacity(0.15),
                                        border: Border.all(
                                          color: _canAfford
                                              ? p.accent.withOpacity(0.6)
                                              : p.food.withOpacity(0.6),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '$secs',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: _canAfford ? p.accent : p.food,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        L10n.t('continue_title'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: p.textPrimary,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.monetization_on_rounded,
                                            size: 12,
                                            color: Color(0xFFFFD700),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.coins}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: p.textPrimary,
                                            ),
                                          ),
                                          if (_canAfford) ...[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              child: Icon(
                                                isFa
                                                    ? Icons.arrow_back_rounded
                                                    : Icons
                                                        .arrow_forward_rounded,
                                                size: 10,
                                                color: p.textMuted,
                                              ),
                                            ),
                                            Text(
                                              '$_after',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFFFD700)
                                                    .withOpacity(0.65),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (!_canAfford) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          L10n.tf('continue_not_enough',
                                              {'n': _shortage}),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: p.food,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    onTap: _handleDecline,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                          minWidth: 48, minHeight: 44),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        L10n.t('continue_decline'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: p.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Material(
                                  color: _canAfford
                                      ? const Color(0xFFFFD700)
                                      : p.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: _canAfford ? _handleContinue : null,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                          minWidth: 48, minHeight: 44),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.monetization_on_rounded,
                                            size: 13,
                                            color: _canAfford
                                                ? Colors.black87
                                                : p.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.cost}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: _canAfford
                                                  ? Colors.black87
                                                  : p.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Emergency Rescue Overlay (طلایی — نجات‌بخش)
// ─────────────────────────────────────────────────

class EmergencyOverlay extends StatefulWidget {
  final GamePalette palette;
  final int coins;
  final int cost;
  final VoidCallback onContinue;
  final VoidCallback onDecline;

  const EmergencyOverlay({
    super.key,
    required this.palette,
    required this.coins,
    required this.cost,
    required this.onContinue,
    required this.onDecline,
  });

  @override
  State<EmergencyOverlay> createState() => _EmergencyOverlayState();
}

class _EmergencyOverlayState extends State<EmergencyOverlay>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFFFD700);

  late final AnimationController _timer;
  late final AnimationController _slideIn;
  final _audio = AudioService();
  bool _handled = false;

  bool get _canAfford => widget.coins >= widget.cost;
  int get _after => widget.coins - widget.cost;
  int get _shortage => widget.cost - widget.coins;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _slideIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _timer.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_handled) {
        _handled = true;
        widget.onDecline();
      }
    });
    _slideIn.forward();
    _timer.forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    _slideIn.dispose();
    super.dispose();
  }

  Future<void> _closeWith(VoidCallback cb) async {
    await _slideIn.reverse();
    if (mounted) cb();
  }

  Future<void> _handleContinue() async {
    if (_handled || !_canAfford) return;
    _handled = true;
    _timer.stop();
    await _audio.playSfx(Sfx.button);
    await _closeWith(widget.onContinue);
  }

  Future<void> _handleDecline() async {
    if (_handled) return;
    _handled = true;
    _timer.stop();
    await _audio.playSfx(Sfx.button);
    await _closeWith(widget.onDecline);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final isFa = L10n.isFa;
    final mq = MediaQuery.of(context);
    final compact = mq.size.width < 360;
    final pad = compact ? 10.0 : 16.0;
    final edge = compact ? 6.0 : 12.0;

    return Positioned.fill(
      child: MediaQuery(
        data: mq.copyWith(
          textScaler: mq.textScaler.clamp(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.15,
          ),
        ),
        child: Stack(
          children: [
            GestureDetector(
              onTap: _handleDecline,
              child: Container(color: Colors.black.withOpacity(0.55)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _slideIn,
                builder: (_, child) {
                  final v = _slideIn.value.clamp(0.0, 1.0);
                  final slideT = Curves.easeOutCubic.transform(v);
                  final fadeT = Curves.easeOut.transform(v);
                  final scaleT = Curves.easeOutBack.transform(v);
                  return FractionalTranslation(
                    translation: Offset(0, 1 - slideT),
                    child: Opacity(
                      opacity: fadeT,
                      child: Transform.scale(
                        scale: 0.92 + (scaleT * 0.08),
                        child: child,
                      ),
                    ),
                  );
                },
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(edge, 0, edge, edge),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        maxHeight: mq.size.height * 0.6,
                      ),
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(pad),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _gold.withOpacity(0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── نوار تایمر ──
                              AnimatedBuilder(
                                animation: _timer,
                                builder: (_, __) {
                                  final remaining =
                                      (1.0 - _timer.value).clamp(0.0, 1.0);
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: remaining,
                                      minHeight: 3,
                                      backgroundColor:
                                          p.border.withOpacity(0.4),
                                      valueColor: AlwaysStoppedAnimation(
                                        _canAfford ? _gold : p.food,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: compact ? 8 : 12),

                              // ── ردیف اطلاعات ──
                              Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _timer,
                                    builder: (_, __) {
                                      final remaining =
                                          (1.0 - _timer.value).clamp(0.0, 1.0);
                                      final secs =
                                          (remaining * 5).ceil().clamp(1, 5);
                                      final size = compact ? 34.0 : 40.0;
                                      return Container(
                                        width: size,
                                        height: size,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _gold.withOpacity(0.15),
                                          border: Border.all(
                                            color: _canAfford
                                                ? _gold.withOpacity(0.6)
                                                : p.food.withOpacity(0.6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          '$secs',
                                          style: TextStyle(
                                            fontSize: compact ? 14 : 16,
                                            fontWeight: FontWeight.w900,
                                            color: _canAfford ? _gold : p.food,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(width: compact ? 8 : 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text('🕊️',
                                                style: TextStyle(
                                                    fontSize:
                                                        compact ? 13 : 15)),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                L10n.t(
                                                    'emergency_rescue_title'),
                                                style: TextStyle(
                                                  fontSize: compact ? 13 : 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: p.textPrimary,
                                                  height: 1.2,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 4,
                                          children: [
                                            Icon(Icons.monetization_on_rounded,
                                                size: 13, color: _gold),
                                            Text(
                                              '${widget.coins}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: p.textPrimary,
                                              ),
                                            ),
                                            if (_canAfford) ...[
                                              Icon(
                                                isFa
                                                    ? Icons.arrow_back_rounded
                                                    : Icons
                                                        .arrow_forward_rounded,
                                                size: 11,
                                                color: p.textMuted,
                                              ),
                                              Text(
                                                '$_after',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      _gold.withOpacity(0.65),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (!_canAfford) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            L10n.tf('continue_not_enough',
                                                {'n': _shortage}),
                                            style: TextStyle(
                                              fontSize: compact ? 10 : 11,
                                              fontWeight: FontWeight.w700,
                                              color: p.food,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: compact ? 10 : 14),

                              // ── ردیف دکمه‌ها ──
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Material(
                                      color: p.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: _handleDecline,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 46,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              L10n.t(
                                                  'emergency_rescue_decline'),
                                              style: TextStyle(
                                                fontSize: compact ? 12 : 13,
                                                fontWeight: FontWeight.w700,
                                                color: p.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: Material(
                                      color: _canAfford ? _gold : p.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap:
                                            _canAfford ? _handleContinue : null,
                                        child: Container(
                                          height: 46,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '🕊️',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: _canAfford
                                                        ? Colors.black87
                                                        : p.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${widget.cost}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: _canAfford
                                                        ? Colors.black87
                                                        : p.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
