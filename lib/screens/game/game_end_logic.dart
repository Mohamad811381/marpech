// ignore_for_file: unused_element, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

part of '../game_screen.dart';

extension _GameEndLogic on _GameScreenState {

  Future<void> _winLevel() async {
    if (_winInProgress || _won) return;
    _winInProgress = true;

    _pulse.stop();
    _timer?.cancel();
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _countdownTimer?.cancel();
    _audio.playSfx(Sfx.newRecord);
    AppHaptics.heavy();
    await StorageService.resetPity(widget.level!.id);
    if (!_everHadShield && !_everHadSlow) {
      await StorageService.incrementPerfectLevels();
    }
    await LevelsService.markCompleted(widget.level!.id);
    await LevelsService.unlockNext(widget.level!.id);

    // 🎯 Stage 2: XP برد مرحله + بونوس فصل
    if (!_levelXpCommitted) {
      var bothDone = true;

      // ۱. XP برد مرحله
      try {
        final result = await PlayerProgressionService.addXP(
          eventId: 'level_win:${widget.level!.id}:first',
          amount: _levelWinXp(widget.level!.id),
          source: 'level',
        );
        if (!result.wasDuplicate && result.xpGained == 0) bothDone = false;
      } catch (e) {
        bothDone = false;
        debugPrint('[LEVEL XP] error: $e');
      }

      // ۲. بونوس فصل (مستقل)
      if (_isLastLevelOfChapter(widget.level!.id)) {
        try {
          final bonus = _chapterBonusFor(widget.level!.id);
          if (bonus > 0) {
            final result = await PlayerProgressionService.addXP(
              eventId: 'chapter:${_chapterIdOf(widget.level!.id)}:bonus',
              amount: bonus,
              source: 'chapter',
            );
            if (!result.wasDuplicate && result.xpGained == 0) bothDone = false;
          }
        } catch (e) {
          bothDone = false;
          debugPrint('[CHAPTER XP] error: $e');
        }
      }

      if (bothDone) _levelXpCommitted = true;
    }

    await AchievementsService.checkUnlocks();
    await DailyChallengesService.recordLevelCompleted();
    await _recordHistory(won: true);
    if (!mounted) return;
    setState(() => _won = true);
  }
  Future<void> _recordHistory({required bool won}) async {
    try {
      final mode = _isLevelMode
          ? GameMode.level
          : _isTimeAttack
              ? GameMode.timeAttack
              : GameMode.free;
      await HistoryService.add(
        GameHistoryEntry(
          timestamp: DateTime.now(),
          score: _score,
          difficulty: d,
          mode: mode,
          snakeLength: _snake.length,
          foodsEaten: _foodsThisGame,
          wasNewRecord: _newRecord,
          levelId: widget.level?.id,
          won: won,
        ),
      );
    } catch (_) {}
  }

  Future<void> _gameOver() async {
    if (_over || _won || _isEnding || _isShowingContinueDialog) return;
    _pulse.stop();

    _timer?.cancel();
    _slowTimer?.cancel();
    _slowTickTimer?.cancel();
    _countdownTimer?.cancel();

    if (_timedOut) {
      // ⏱️ Timeout → مستقیم (بدون shake)
      if (_canContinue) {
        await _showContinueDialog();
        return;
      }
      await _finalizeGameOver();
      return;
    }

    // 💥 برخورد → shake + صدا
    _triggerShake(intensity: 1.0);
    _audio.playSfx(Sfx.gameOver);
    AppHaptics.heavy();

    // ⏳ صبر کن تا shake تموم شه (۳۸۰ms) + یه ذره مکث
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    if (_canContinue) {
      await _showContinueDialog();
      return;
    }

    _startEndCountdown();
  }
  void _startEndCountdown() {
    _endCountdownTimer?.cancel();
    setState(() => _endCountdown = 3);

    _endCountdownTimer =
        Timer.periodic(const Duration(milliseconds: 450), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_endCountdown > 1) {
        setState(() => _endCountdown--);
        AppHaptics.selection();
        if (SettingsService.current.sfx) {
          _audio.playSfx(Sfx.button);
        }
      } else {
        t.cancel();
        await _finalizeGameOver();
      }
    });
  }

// ═══════════════════════════════════════════════════════════
  // 🌀 Coil Placement for Emergency Rescue Respawn
  // ═══════════════════════════════════════════════════════════

  Future<void> _finalizeGameOver() async {
    if (_timedOut) {
      _audio.playSfx(Sfx.gameOver);
      AppHaptics.medium();
    }

    await _recordHistory(won: false);
    if (_isLevelMode) {
      _pityCount = await StorageService.incrementPity(widget.level!.id);
    }

    if (!_isLevelMode) {
      if (_newRecord) {
        await GhostService.save(
          difficulty: d,
          timeAttack: _isTimeAttack,
          ticks: _currentRecording,
        );
        _ghostRecording = GhostRecording(List<int>.from(_currentRecording));
      }

      final newAch = await AchievementsService.recordGame(
        score: _score,
        snakeLength: _snake.length,
      );
      _newAchievements = newAch;

      // 🎯 Stage 2: XP بازی (یک‌بار در session)
      if (!_gameXpCommitted) {
        final gameXp = _calculateGameXp();
        if (gameXp > 0) {
          try {
            final result = await PlayerProgressionService.addXP(
              eventId: 'game:$_gameSessionId',
              amount: gameXp,
              source: 'game',
            );
            if (result.wasDuplicate || result.xpGained > 0) {
              _gameXpCommitted = true;
            }
          } catch (e) {
            debugPrint('[GAME XP] error: $e');
          }
        } else {
          _gameXpCommitted = true;
        }
      }

      await DailyChallengesService.recordGameEnd(
        score: _score,
        foodsEaten: _foodsThisGame,
        goldenApples: _goldenApplesEaten,
        usedShield: _everHadShield,
        usedSlow: _everHadSlow,
        snakeLength: _snake.length,
        isTimeAttack: _isTimeAttack,
      );

      await MissionsService.recordGame(
        usedShield: _everHadShield,
        goldenApplesThisGame: _goldenApplesEaten,
        combosThisGame: _combosThisGame,
      );
    }

    if (!mounted) return;
    setState(() {
      _over = true;
      _endCountdown = 0;
    });

    if (_newRecord) {
      Future.delayed(const Duration(milliseconds: 450), () {
        _audio.playSfx(Sfx.newRecord);
      });
    }
  }



}
