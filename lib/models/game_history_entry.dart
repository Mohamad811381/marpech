import 'package:marpech/services/localization_service.dart';

import 'difficulty.dart';

enum GameMode { free, timeAttack, level }


extension GameModeExt on GameMode {
  String get label {
    switch (this) {
      case GameMode.free:
        return L10n.t('game_mode_free');
      case GameMode.timeAttack:
        return L10n.t('game_mode_time_attack');
      case GameMode.level:
        return L10n.t('game_mode_level');
    }
  }
}
class GameHistoryEntry {
  final DateTime timestamp;
  final int score;
  final Difficulty difficulty;
  final GameMode mode;
  final int snakeLength;
  final int foodsEaten;
  final bool wasNewRecord;
  final int? levelId;
  final bool won;

  const GameHistoryEntry({
    required this.timestamp,
    required this.score,
    required this.difficulty,
    required this.mode,
    required this.snakeLength,
    required this.foodsEaten,
    required this.wasNewRecord,
    this.levelId,
    this.won = false,
  });

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'score': score,
        'diff': difficulty.name,
        'mode': mode.name,
        'len': snakeLength,
        'foods': foodsEaten,
        'rec': wasNewRecord,
        'lid': levelId,
        'won': won,
      };

  factory GameHistoryEntry.fromJson(Map<String, dynamic> j) {
    return GameHistoryEntry(
      timestamp: DateTime.parse(j['ts'] as String),
      score: j['score'] as int,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == j['diff'],
        orElse: () => Difficulty.normal,
      ),
      mode: GameMode.values.firstWhere(
        (m) => m.name == j['mode'],
        orElse: () => GameMode.free,
      ),
      snakeLength: j['len'] as int,
      foodsEaten: j['foods'] as int,
      wasNewRecord: j['rec'] as bool? ?? false,
      levelId: j['lid'] as int?,
      won: j['won'] as bool? ?? false,
    );
  }
}
