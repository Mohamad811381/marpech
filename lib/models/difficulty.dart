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
}
