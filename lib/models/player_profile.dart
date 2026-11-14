
/// پروفایل بازیکن — از XP کل مشتق می‌شود (level/xpCurrent محاسبه‌شده)
class PlayerProfile {
  final int xpTotal;
  final Map<String, int> xpBySource;
  final Set<int> levelRewardsGranted;
  final Set<String> processedEvents;

  const PlayerProfile({
    required this.xpTotal,
    required this.xpBySource,
    required this.levelRewardsGranted,
    required this.processedEvents,
  });

  factory PlayerProfile.empty() => const PlayerProfile(
        xpTotal: 0,
        xpBySource: {},
        levelRewardsGranted: {},
        processedEvents: {},
      );

  Map<String, dynamic> toJson() => {
        'xp_total': xpTotal,
        'xp_by_source': xpBySource,
        'level_rewards_granted':
            levelRewardsGranted.map((e) => e.toString()).toList(),
        'processed_events': processedEvents.toList(),
        'schema_version': 1,
      };
}
