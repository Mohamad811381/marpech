import '../services/localization_service.dart';

enum SnakeSkin {
  basic('basic'),
  fire('fire'),
  pixel('pixel'),
  galaxy('galaxy'),
  rainbow('rainbow'),
  ice('ice'),
  gold('gold'),
  neon('neon'),
  shadow('shadow'),
  veteranSnakeSkin('veteran_snake_skin');
  

  final String id;
  const SnakeSkin(this.id);

  String get name => L10n.t('skin_snake_${id}_name');
  String get desc => L10n.t('skin_snake_${id}_desc');

  static SnakeSkin fromId(String? id) =>
      SnakeSkin.values.firstWhere((s) => s.id == id,
          orElse: () => SnakeSkin.basic);
}

enum GhostSkin {
  basic('basic'),
  golden('golden'),
  dragon('dragon'),
  spirit('spirit'),
  rainbow('rainbow'),
  ice('ice'),
  electric('electric'),
  phantom('phantom'),
  blossom('blossom'),
  eliteGhostSkin('elite_ghost_skin');

  final String id;
  const GhostSkin(this.id);

  String get name => L10n.t('skin_ghost_${id}_name');
  String get desc => L10n.t('skin_ghost_${id}_desc');

  static GhostSkin fromId(String? id) =>
      GhostSkin.values.firstWhere((s) => s.id == id,
          orElse: () => GhostSkin.basic);
}

enum FoodSkin {
  basic('basic'),
  pizza('pizza'),
  burger('burger'),
  donut('donut'),
  grape('grape'),
  star('star'),
  cherry('cherry'),
  watermelon('watermelon'),
  goldenTrophyFood('golden_trophy_food');
  final String id;
  const FoodSkin(this.id);

  String get name => L10n.t('skin_food_${id}_name');
  String get desc => L10n.t('skin_food_${id}_desc');

  static FoodSkin fromId(String? id) =>
      FoodSkin.values.firstWhere((s) => s.id == id,
          orElse: () => FoodSkin.basic);
}


enum TrailEffect {
  none('none'),
  neon('neon'),
  fire('fire'),
  stars('stars'),
  smoke('smoke'),
  rainbow('rainbow'),
  ice('ice'),
  electric('electric'),
  blossom('blossom'),
  phantom('phantom'),
  water('water'),
  bronzeTrail('bronze_trail'),
  mythicTrail('mythic_trail');

  final String id;
  const TrailEffect(this.id);

  String get name => L10n.t('skin_trail_${id}_name');
  String get desc => L10n.t('skin_trail_${id}_desc');

  static TrailEffect fromId(String? id) =>
      TrailEffect.values.firstWhere((s) => s.id == id,
          orElse: () => TrailEffect.none);
}