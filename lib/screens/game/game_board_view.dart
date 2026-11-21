// ignore_for_file: unused_element, deprecated_member_use

part of '../game_screen.dart';

extension _GameBoardView on _GameScreenState {




  Widget _header() {
    return Column(
      children: [
        Row(
          children: [
            GameCircleButton(
              palette: p,
              icon: Icons.arrow_back_rounded,
              onTap: _exit,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: L10n.t('game_score'),
                value: '$_score',
                color: p.accent,
                palette: p,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _isAnyTimed
                  ? TimerCard(
                      palette: p,
                      secondsLeft: _secondsLeft,
                      pulse: _pulse,
                    )
                  : _isLevelMode
                      ? StatCard(
                          label: L10n.t('game_progress'),
                          value: '$_foodsEaten/${widget.level!.targetFoods}',
                          color: p.food,
                          palette: p,
                        )
                      : StatCard(
                          label: L10n.t('game_record'),
                          value: '$_best',
                          color: p.food,
                          palette: p,
                        ),
            ),
            const SizedBox(width: 8),
            GameCircleButton(
              palette: p,
              icon: (_over || _won)
                  ? Icons.refresh_rounded
                  : (_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              onTap: (_over || _won) ? _reset : _togglePause,
            ),
          ],
        ),
        if (_isTimedLevel) ...[
          const SizedBox(height: 8),
          FoodProgressBar(
            palette: p,
            eaten: _foodsEaten,
            target: widget.level!.targetFoods,
          ),
        ],
      ],
    );
  }

  Widget _board(GameSettings settings) {
    final animations = <Listenable>[_pulse, _moveAnim];
    // _rainbow animation دیگه لازم نیست (اسکین رنگین‌کمان از _pulse استفاده می‌کنه)
    if (settings.wrapEffect) animations.add(_wrapAnim);
    final hasNextLevel =
        _isLevelMode && LevelsService.getNext(widget.level!.id) != null;
    return AspectRatio(
      aspectRatio: 1,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: p.board,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: p.accent.withOpacity(0.10),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ═══════════ 👻 تغییر ۱: Opacity روی بورد ═══════════
                GestureDetector(
                  onTapDown: (_) => _focus.requestFocus(),
                  onPanEnd: _onSwipe,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(animations),
                    builder: (context, _) => Opacity(
                      opacity: _ghostActive ? 0.55 : 1.0,
                      child: CustomPaint(
                        painter: BoardPainter(
                          snake: _snake,
                          prevSnake: _prevSnake,
                          moveProgress: _moveAnim.value,
                          snakeSkin: _snakeSkin,
                          foodSkin: _foodSkin,
                          trail: _trail,
                          pattern: _pattern,
                          patternIntensity: _patternIntensity,
                          ghostSkin: _ghostSkin,
                          timePhase: _pulse.value,
                          food: _food,
                          dir: _dir,
                          palette: p,
                          pulse: _pulse.value,
                          cols: cols,
                          rows: rows,
                          powerUpType: _currentPowerUp?.type,
                          showGrid: settings.showGrid,
                          rainbow: false,
                          rainbowPhase: _rainbow.value,
                          wrapEvent: _wrapEvent,
                          wrapProgress: _wrapAnim.value,
                          walls: _walls,
                          ghost: settings.showGhost ? _ghostBody() : null,
                          portals: _portals,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _particles,
                    builder: (context, _) => CustomPaint(
                      painter: ParticlePainter(
                        burst: _currentBurst,
                        progress: _particles.value,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                if (_isComboActive)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) {
                        final alpha = 0.18 + 0.22 * _pulse.value;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(alpha),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withOpacity(alpha * 0.4),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _comboFlash,
                    builder: (_, __) {
                      if (_comboFlash.value >= 1.0) {
                        return const SizedBox.shrink();
                      }
                      final pr = _comboFlash.value;
                      final alpha = (1 - pr).clamp(0.0, 1.0);
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: const Color(0xFFFFD700)
                                .withOpacity(alpha * 0.9),
                            width: 3 + 8 * (1 - pr),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withOpacity(alpha * 0.55),
                              blurRadius: 30 * (1 - pr) + 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_isIntroPlaying)
                  AnimatedBuilder(
                    animation: _introAnim,
                    builder: (_, __) => IntroOverlay(
                      type: _introAnimation,
                      progress: _introAnim.value,
                      palette: p,
                    ),
                  ),
                if (_isStarting)
                  StartCountdownOverlay(
                    palette: p,
                    countdown: _countdown,
                    showPity: _isLevelMode && _pityShields > 0,
                    pityShields: _pityShields,
                  ),
                // ═══════════ 👻 تغییر ۲: Ghost Border Overlay ═══════════
                if (_ghostActive)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: _isEmergencyRecovery
                              ? const Color(0xFFFFD700).withOpacity(0.7)
                              : const Color(0xFF00F0FF).withOpacity(0.7),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isEmergencyRecovery
                                ? const Color(0xFFFFD700).withOpacity(0.5)
                                : const Color(0xFF00F0FF).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showShieldFlash)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: _isEmergencyRecovery
                              ? const Color(0xFFFFD700).withOpacity(0.9)
                              : const Color(0xFF00F0FF).withOpacity(0.8),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isEmergencyRecovery
                                ? const Color(0xFFFFD700).withOpacity(0.6)
                                : const Color(0xFF00F0FF).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isEmergencyRecovery ? '🕊️' : '🛡️',
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                  ),
                if (_isEnding)
                  EndCountdownOverlay(
                    palette: p,
                    endCountdown: _endCountdown,
                  ),
                if (_isShowingContinueDialog)
                  ContinueOverlay(
                    palette: p,
                    coins: _currentCoins,
                    cost: _continueCost,
                    onContinue: _handleContinue,
                    onDecline: _handleContinueDecline,
                  ),
                if (_isShowingEmergencyDialog)
                  EmergencyOverlay(
                    palette: p,
                    coins: _currentCoins,
                    cost: _emergencyRescuePrice,
                    onContinue: _handleEmergencyAccept,
                    onDecline: _handleEmergencyDecline,
                  ),
                if (_over || _paused || _won)
                  GameOverlay(
                    palette: p,
                    won: _won,
                    over: _over,
                    paused: _paused,
                    timedOut: _timedOut,
                    isLevelMode: _isLevelMode,
                    isTimeAttack: _isTimeAttack,
                    level: widget.level,
                    score: _score,
                    best: _best,
                    foodsEaten: _foodsEaten,
                    newRecord: _newRecord,
                    newAchievements: _newAchievements,
                    hasNextLevel: hasNextLevel,
                    onBack: () => Navigator.of(context).pop(),
                    onReset: _reset,
                    onTogglePause: _togglePause,
                    onNextLevel: _goToNextLevel,
                    onOpenWinner: _openWinner,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }




}