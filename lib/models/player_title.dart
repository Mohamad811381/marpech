/// عنوان بازیکن — محاسبه‌شده از سطح، ذخیره نمی‌شود
enum PlayerTitle {
  beginner('beginner', 1, 4),
  rookie('rookie', 5, 9),
  skilled('skilled', 10, 19),
  expert('expert', 20, 29),
  snakeMaster('snake_master', 30, 39),
  elite('elite', 40, 49),
  champion('champion', 50, 64),
  legend('legend', 65, 79),
  myth('myth', 80, 89),
  immortal('immortal', 90, 99),
  marpechMaster('marpech_master', 100, 100);

  final String id;
  final int minLevel;
  final int maxLevel;

  const PlayerTitle(this.id, this.minLevel, this.maxLevel);

  static PlayerTitle forLevel(int level) {
    for (final t in PlayerTitle.values) {
      if (level >= t.minLevel && level <= t.maxLevel) return t;
    }
    return PlayerTitle.beginner;
  }

  String get nameKey => 'player_title_$id';
}
