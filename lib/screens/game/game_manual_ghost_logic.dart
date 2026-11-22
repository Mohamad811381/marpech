// ignore_for_file: unused_element, invalid_use_of_protected_member, deprecated_member_use

part of '../game_screen.dart';

extension _GameManualGhostLogic on _GameScreenState {
  bool get _canUseManualGhost =>
      _ghostCharges > 0 &&
      !_manualGhost &&
      !_over &&
      !_won &&
      !_paused &&
      !_isStarting &&
      !_isEnding &&
      !_isShowingContinueDialog &&
      !_isShowingEmergencyDialog &&
      !_isRecovering;

  void _activateManualGhost() {
    if (!_canUseManualGhost) return;
    _manualGhostTimer?.cancel();
    setState(() {
      _ghostCharges--;
      _manualGhost = true;
      _manualGhostTimeUp = false;
      _manualGhostLife = 4;
      _manualGhostGrace = 0;
    });
    AppHaptics.medium();
    _audio.playSfx(Sfx.newRecord);

    _manualGhostTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      if (_manualGhostLife > 0) {
        setState(() {
          _manualGhostLife--;
          if (_manualGhostLife <= 0) _manualGhostTimeUp = true;
        });
        if (_manualGhostTimeUp) _tryEndManualGhost();
        return;
      }
      if (!_manualGhost) {
        _manualGhostTimer?.cancel();
        return;
      }
      setState(() => _manualGhostGrace++);
      if (_manualGhostGrace >= 3) _killStuckGhost();
    });
  }

  bool _snakeIsClear() {
    if (_snake.toSet().length != _snake.length) return false;
    final walls = _walls;
    for (final c in _snake) {
      if (walls.contains(c) || _botSnake.contains(c)) return false;
    }
    return true;
  }

  void _tryEndManualGhost() {
    if (!_manualGhost || !_manualGhostTimeUp) return;
    if (!_snakeIsClear()) return;
    _manualGhostTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _manualGhost = false;
      _manualGhostTimeUp = false;
    });
    AppHaptics.selection();
  }

  void _killStuckGhost() {
    _manualGhostTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _manualGhost = false;
      _manualGhostTimeUp = false;
    });
    _gameOver();
  }

  Widget _ghostButton() {
    const cyan = Color(0xFF00F0FF);
    final enabled = _canUseManualGhost;
    final active = _manualGhost;
    if (_ghostCharges <= 0 && !active) return const SizedBox(height: 30);
    return GestureDetector(
      onTap: enabled ? _activateManualGhost : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: (enabled || active) ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? cyan.withOpacity(0.15)
                : p.textPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? cyan.withOpacity(0.8) : p.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👻', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                active
                    ? (_manualGhostTimeUp
                        ? '⚠ ${3 - _manualGhostGrace}'
                        : '${_manualGhostLife}s')
                    : (_ghostCharges > 1
                        ? '${L10n.t('game_ghost_chip')} ×$_ghostCharges'
                        : L10n.t('game_ghost_chip')),
                style: TextStyle(
                  color: active ? cyan : p.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
