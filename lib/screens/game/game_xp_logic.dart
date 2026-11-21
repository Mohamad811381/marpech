// ignore_for_file: unused_element

part of '../game_screen.dart';

extension _GameXpLogic on _GameScreenState {




  // 🎯 Stage 2: XP helpers

  int _calculateGameXp() {
    if (_isLevelMode) return 0;
    if (_score < 10) return 0;
    if (_isTimeAttack && _foodsThisGame < 3) return 0;

    int base;
    if (_isTimeAttack) {
      base = 30;
    } else {
      switch (d) {
        case Difficulty.easy:
          base = 20;
          break;
        case Difficulty.normal:
          base = 25;
          break;
        case Difficulty.hard:
          base = 35;
          break;
      }
    }

    return base +
        _foodsThisGame * 1 +
        _goldenApplesEaten * 5 +
        _combosThisGame * 8 +
        (_newRecord ? 30 : 0);
  }

  int _levelWinXp(int levelId) {
    if (levelId <= 10) return 25;
    if (levelId <= 20) return 40;
    if (levelId <= 30) return 55;
    return 75;
  }

  int _chapterIdOf(int levelId) {
    for (final c in LevelsService.chapters) {
      if (levelId >= c.startLevelId && levelId <= c.endLevelId) {
        return c.id;
      }
    }
    return 1;
  }

  bool _isLastLevelOfChapter(int levelId) {
    for (final c in LevelsService.chapters) {
      if (levelId == c.endLevelId) return true;
    }
    return false;
  }

  int _chapterBonusFor(int levelId) {
    final chapterId = _chapterIdOf(levelId);
    switch (chapterId) {
      case 1:
        return 150;
      case 2:
        return 200;
      case 3:
        return 250;
      case 4:
        return 300;
      default:
        return 0;
    }
  }



}