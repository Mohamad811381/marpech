// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/game_palette.dart';
import '../../services/localization_service.dart';
import '../../widgets/stat_card.dart';

// ─────────────────────────────────────────────────
// PowerUp HUD
// ─────────────────────────────────────────────────

class PowerUpHud extends StatelessWidget {
  final GamePalette palette;
  final int shieldCount;
  final bool slowActive;
  final int slowRemaining;
  final bool comboActive;
  final double comboMultiplier;
  final bool showGhost;

  const PowerUpHud({
    super.key,
    required this.palette,
    required this.shieldCount,
    required this.slowActive,
    required this.slowRemaining,
    required this.comboActive,
    required this.comboMultiplier,
    required this.showGhost,
  });

  @override
  Widget build(BuildContext context) {
    final hasShield = shieldCount > 0;
    final hasSlow = slowActive;
    final hasCombo = comboActive;
    final hasGhost = showGhost;

    if (!hasShield && !hasSlow && !hasGhost) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          if (hasGhost) _GhostChip(palette: palette),
          if (hasShield) _ShieldChip(palette: palette, count: shieldCount),
          if (hasSlow) _SlowChip(palette: palette, remaining: slowRemaining),
          if (hasCombo)
            _ComboChip(palette: palette, multiplier: comboMultiplier),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Timer Card
// ─────────────────────────────────────────────────

class TimerCard extends StatelessWidget {
  final GamePalette palette;
  final int secondsLeft;
  final Animation<double> pulse;

  const TimerCard({
    super.key,
    required this.palette,
    required this.secondsLeft,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final secs = secondsLeft.clamp(0, 999);
    final mins = secs ~/ 60;
    final rest = secs % 60;
    final text =
        mins > 0 ? '$mins:${rest.toString().padLeft(2, '0')}' : '${secs}s';
    final color = secs > 20
        ? palette.accent
        : secs > 10
            ? palette.food
            : const Color(0xFFFF3D6A);

    final card = StatCard(
      label: L10n.t('game_time'),
      value: text,
      color: color,
      palette: palette,
    );

    if (secs > 10) return card;
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final scale = 1.0 + 0.06 * pulse.value;
        return Transform.scale(scale: scale, child: card);
      },
    );
  }
}

// ─────────────────────────────────────────────────
// Food Progress Bar
// ─────────────────────────────────────────────────

class FoodProgressBar extends StatelessWidget {
  final GamePalette palette;
  final int eaten;
  final int target;

  const FoodProgressBar({
    super.key,
    required this.palette,
    required this.eaten,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = eaten.clamp(0, target);
    final progress = target == 0 ? 0.0 : clamped / target;
    final completed = clamped >= target;
    final color = completed ? palette.accent : palette.food;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          const Text('🍎', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: palette.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$clamped/$target',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (completed) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_rounded, color: palette.accent, size: 16),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Game Circle Button
// ─────────────────────────────────────────────────

class GameCircleButton extends StatelessWidget {
  final GamePalette palette;
  final IconData icon;
  final VoidCallback onTap;

  const GameCircleButton({
    super.key,
    required this.palette,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surface,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFF22303F))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: palette.accent, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Chips (private)
// ─────────────────────────────────────────────────

class _GhostChip extends StatelessWidget {
  final GamePalette palette;
  const _GhostChip({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
             color: palette.textPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👻', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            L10n.t('game_ghost_chip'),
            style: TextStyle(
              color: palette.textPrimary,              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldChip extends StatelessWidget {
  final GamePalette palette;
  final int count;
  const _ShieldChip({required this.palette, required this.count});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF00F0FF);
    final label = count > 1
        ? L10n.tf('game_shield_count', {'n': count})
        : L10n.t('game_shield');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlowChip extends StatelessWidget {
  final GamePalette palette;
  final int remaining;
  const _SlowChip({required this.palette, required this.remaining});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8A7BFF);
    final label = remaining > 0
        ? L10n.tf('game_slow_count', {'n': remaining})
        : L10n.t('game_slow');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_bottom_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboChip extends StatelessWidget {
  final GamePalette palette;
  final double multiplier;
  const _ComboChip({required this.palette, required this.multiplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8A5B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            L10n.tf('game_combo', {'n': multiplier.toStringAsFixed(1)}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}