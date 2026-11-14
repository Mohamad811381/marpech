// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/localization_service.dart';

enum ChallengeType {
  totalScore,
  totalFood,
  goldenApples,
  gamesPlayed,
  noShieldGames,
  noSlowGames,
  longestSnake,
  levelsCompleted,
  timeAttackBestScore,
}

class DailyChallenge {
  final String id;
  final ChallengeType type;
  final int target;
  final int progress;
  final int reward;
  final bool claimed;

  const DailyChallenge({
    required this.id,
    required this.type,
    required this.target,
    required this.progress,
    required this.reward,
    required this.claimed,
  });

  /// عنوان ترجمه‌شده — از تایپ و هدف ساخته می‌شه
  String get title => L10n.tf(
        'challenge_title_${type.name}',
        {'n': target},
      );

  bool get isCompleted => progress >= target;
  bool get canClaim => isCompleted && !claimed;
  double get ratio =>
      target == 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);

  IconData get icon {
    switch (type) {
      case ChallengeType.totalScore:
        return Icons.trending_up_rounded;
      case ChallengeType.totalFood:
        return Icons.restaurant_rounded;
      case ChallengeType.goldenApples:
        return Icons.star_rounded;
      case ChallengeType.gamesPlayed:
        return Icons.sports_esports_rounded;
      case ChallengeType.noShieldGames:
        return Icons.shield_outlined;
      case ChallengeType.noSlowGames:
        return Icons.hourglass_empty_rounded;
      case ChallengeType.longestSnake:
        return Icons.straighten_rounded;
      case ChallengeType.levelsCompleted:
        return Icons.map_rounded;
      case ChallengeType.timeAttackBestScore:
        return Icons.timer_rounded;
    }
  }

  Color get color {
    switch (type) {
      case ChallengeType.totalScore:
        return const Color(0xFF4CE0B3);
      case ChallengeType.totalFood:
        return const Color(0xFFFF6B8A);
      case ChallengeType.goldenApples:
        return const Color(0xFFFFD700);
      case ChallengeType.gamesPlayed:
        return const Color(0xFF00F0FF);
      case ChallengeType.noShieldGames:
        return const Color(0xFF8A7BFF);
      case ChallengeType.noSlowGames:
        return const Color(0xFFFF8A5B);
      case ChallengeType.longestSnake:
        return const Color(0xFF7BFFD0);
      case ChallengeType.levelsCompleted:
        return const Color(0xFF4CE0B3);
      case ChallengeType.timeAttackBestScore:
        return const Color(0xFFFF8A5B);
    }
  }

  DailyChallenge copyWith({int? progress, bool? claimed}) {
    return DailyChallenge(
      id: id,
      type: type,
      target: target,
      progress: progress ?? this.progress,
      reward: reward,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'target': target,
        'progress': progress,
        'reward': reward,
        'claimed': claimed,
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> j) {
    return DailyChallenge(
      id: j['id'] as String,
      type: ChallengeType.values.firstWhere(
        (t) => t.name == j['type'],
        orElse: () => ChallengeType.totalScore,
      ),
      target: j['target'] as int,
      progress: j['progress'] as int,
      reward: j['reward'] as int,
      claimed: j['claimed'] as bool,
    );
  }
}