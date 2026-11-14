import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/models/player_title.dart';
import 'package:marpech/services/player_progression_service.dart';
import 'package:marpech/widgets/level_up_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    PlayerProgressionService.resetStateForTests();
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
  });

  test('batch preserves intermediate levels and rewards', () async {
    await PlayerProgressionService.addXP(
      eventId: 'path:1',
      amount: PlayerProgressionService.cumulativeXP(5),
      source: 'game',
    );
    final results = PlayerProgressionService.consumePendingLevelUps();
    final xp =
        (await SharedPreferences.getInstance()).getInt('player_xp_total') ?? 0;
    final batch = LevelUpBatch.fromResults(results, xp);
    expect(batch.oldLevel, 1);
    expect(batch.newLevel, 5);
    expect(batch.levelPath, [1, 2, 3, 4, 5]);
    expect(batch.totalXpGained, PlayerProgressionService.cumulativeXP(5));
    expect(batch.oldTitle, PlayerTitle.beginner);
    expect(batch.newTitle, PlayerTitle.rookie);
    expect(batch.titlesEarned, [PlayerTitle.rookie]);
    expect(batch.milestones.length, 1);
    expect(batch.milestones.first.level, 5);
    expect(batch.milestones.first.coins, 30);
    expect(batch.cosmetics, isEmpty);
  });

  test('L1 to L15: multiple titles earned', () async {
    await PlayerProgressionService.addXP(
      eventId: 'path:2',
      amount: PlayerProgressionService.cumulativeXP(15),
      source: 'game',
    );
    final results = PlayerProgressionService.consumePendingLevelUps();
    final xp =
        (await SharedPreferences.getInstance()).getInt('player_xp_total') ?? 0;
    final batch = LevelUpBatch.fromResults(results, xp);
    expect(batch.oldLevel, 1);
    expect(batch.newLevel, 15);
    expect(batch.levelPath.length, 15);
    expect(batch.titlesEarned, [PlayerTitle.rookie, PlayerTitle.skilled]);
    expect(batch.milestones.length, 3);
    expect(batch.milestones.map((m) => m.level).toSet(), {5, 10, 15});
  });
}
