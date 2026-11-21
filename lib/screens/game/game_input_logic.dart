// ignore_for_file: unused_element, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

part of '../game_screen.dart';

extension _GameInputLogic on _GameScreenState {
  void _turn(math.Point<int> delta) {
    if (_over ||
        _won ||
        _paused ||
        _isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      return;
    }
    if (delta == const math.Point(0, 0)) return;
    if (delta.x == -_dir.x && delta.y == -_dir.y) return;
    if (delta == _dir) return;
    _queued = delta;
  }

  void _togglePause() {
    if (_over ||
        _won ||
        _isStarting ||
        _isEnding ||
        _isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      return;
    }
    _pulse.stop();
    final next = !_paused;
    setState(() => _paused = next);
    if (next) {
      _audio.pauseMusic();
      _countdownTimer?.cancel();
    } else {
      _audio.resumeMusic();
      if (!_pulse.isAnimating) _pulse.repeat();
      if (_canRunClock) _startCountdown();
    }
  }

  void _onSwipe(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    if (v.distance < 80) return;
    if (v.dx.abs() > v.dy.abs()) {
      _turn(math.Point(v.dx > 0 ? 1 : -1, 0));
    } else {
      _turn(math.Point(0, v.dy > 0 ? 1 : -1));
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;

    final dir = _GameScreenState._keyMap[k];
    if (dir != null) {
      _turn(dir);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      _togglePause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _exit() async {
    if (_isShowingContinueDialog ||
        _isShowingEmergencyDialog ||
        _isRecovering) {
      return;
    }
    final wasPaused = _paused;
    if (!_isStarting && !_isEnding) {
      setState(() => _paused = true);
      _audio.pauseMusic();
      _countdownTimer?.cancel();
    }

    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          L10n.t('game_exit_title'),
          style: TextStyle(color: p.textPrimary),
        ),
        content: Text(
          L10n.t('game_exit_content'),
          style: TextStyle(color: p.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              L10n.t('continue_btn'),
              style: TextStyle(color: p.accent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              L10n.t('back'),
              style: TextStyle(color: p.food),
            ),
          ),
        ],
      ),
    );

    if (leave == true) {
      _countdownTimer?.cancel();
      _startCountdownTimer?.cancel();
      _endCountdownTimer?.cancel();
      _slowTimer?.cancel();
      _slowTickTimer?.cancel();
      _timer?.cancel();
      _audio.stopMusic();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (mounted && !wasPaused && !_isStarting && !_isEnding) {
      setState(() => _paused = false);
      _audio.resumeMusic();
      if (!_pulse.isAnimating) _pulse.repeat(); // ← اضافه
      if (_canRunClock) {
        _startCountdown();
      }
    }
  }

  void _goToNextLevel() {
    final next = LevelsService.getNext(widget.level!.id);
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          difficulty: d,
          palette: p,
          level: next,
        ),
      ),
    );
  }

  Future<void> _openWinner() async {
    await StorageService.markWinnerSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WinnerScreen(palette: p),
      ),
    );
  }
}
