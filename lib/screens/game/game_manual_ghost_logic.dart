// ignore_for_file: unused_element, invalid_use_of_protected_member, deprecated_member_use

part of '../game_screen.dart';

extension _GameManualGhostLogic on _GameScreenState {
  bool get _canUseManualGhost =>
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
      _manualGhost = true;
      _manualGhostTimeUp = false;
      _manualGhostLife = 4;
    });
    AppHaptics.medium();
    _audio.playSfx(Sfx.newRecord);

    _manualGhostTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      if (_manualGhostLife > 0) setState(() => _manualGhostLife--);
      if (_manualGhostLife <= 0) {
        _manualGhostTimer?.cancel();
        _manualGhostTimeUp = true;
        _tryEndManualGhost();
      }
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

  Widget _ghostButton() {
    const cyan = Color(0xFF00F0FF);
    final enabled = _canUseManualGhost;
    final active = _manualGhost;
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
                    ? (_manualGhostTimeUp ? '…' : '${_manualGhostLife}s')
                    : L10n.t('game_ghost_chip'),
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
