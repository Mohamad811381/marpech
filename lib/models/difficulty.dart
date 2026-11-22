import '../services/localization_service.dart';

enum Difficulty {
  easy(Duration(milliseconds: 200), true, 1),
  normal(Duration(milliseconds: 140), false, 2),
  hard(Duration(milliseconds: 90), false, 3);

  final Duration tick;
  final bool wrap;
  final int multiplier;

  const Difficulty(this.tick, this.wrap, this.multiplier);

  String get label => L10n.t('diff_${name}_label');
  String get subtitle => L10n.t('diff_${name}_sub');
  
  /// احتمال اشتباه ربات در هر حرکت
  double get botMistakeChance => switch (this) {
        Difficulty.easy => 0.30,
        Difficulty.normal => 0.08,
        Difficulty.hard => 0.0,
      };

  /// ربات قبل از حرکت چک می‌کنه که بن‌بست نباشه؟
  bool get botLooksAhead => this != Difficulty.easy;
}
