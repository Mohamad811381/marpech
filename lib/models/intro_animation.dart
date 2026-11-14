import '../services/localization_service.dart';

enum IntroAnimation {
  none('none'),
  rocket('rocket'),
  portal('portal'),
  lightning('lightning'),
  sparkle('sparkle'),
  comet('comet'),
  tornado('tornado'),
  explosion('explosion'),
  crystal('crystal'),
  championIntro('champion_intro');

  final String id;
  const IntroAnimation(this.id);

  String get name => L10n.t('intro_${id}_name');
  String get desc => L10n.t('intro_${id}_desc');

  static IntroAnimation fromId(String? id) =>
      IntroAnimation.values.firstWhere(
        (a) => a.id == id,
        orElse: () => IntroAnimation.none,
      );
}