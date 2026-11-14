import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/models/player_title.dart';
import 'package:marpech/services/player_progression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    if (PlayerProgressionService.pendingLevelUps.debugHasListeners) {
      fail('Listener leak from previous test (pendingLevelUps)');
    }
    if (PlayerProgressionService.dialogSafe.debugHasListeners) {
      fail('Listener leak from previous test (dialogSafe)');
    }
    PlayerProgressionService.resetStateForTests();
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
  });

  tearDown(() {
    PlayerProgressionService.resetStateForTests();
  });

  group('Level-up queue', () {
    test('valid level-up event is enqueued', () async {
      final before = PlayerProgressionService.pendingLevelUps.value.length;
      await PlayerProgressionService.addXP(
        eventId: 't:1',
        amount: PlayerProgressionService.cumulativeXP(2),
        source: 'test',
      );
      final after = PlayerProgressionService.pendingLevelUps.value.length;
      expect(after, before + 1);
      expect(PlayerProgressionService.pendingLevelUps.value.last.didLevelUp,
          isTrue);
    });

    test('duplicate event is not enqueued', () async {
      await PlayerProgressionService.addXP(
        eventId: 't:dup',
        amount: PlayerProgressionService.cumulativeXP(2),
        source: 'test',
      );
      final countAfterFirst =
          PlayerProgressionService.pendingLevelUps.value.length;

      await PlayerProgressionService.addXP(
        eventId: 't:dup',
        amount: PlayerProgressionService.cumulativeXP(2),
        source: 'test',
      );
      expect(PlayerProgressionService.pendingLevelUps.value.length,
          countAfterFirst);
    });

    test('event without level-up is not enqueued', () async {
      await PlayerProgressionService.addXP(
        eventId: 't:nochange',
        amount: 1,
        source: 'test',
      );
      expect(PlayerProgressionService.pendingLevelUps.value, isEmpty);
    });

    test('dialog blockers prevent safe display', () {
      expect(PlayerProgressionService.dialogSafe.value, isTrue);
      final owner1 = Object();
      final owner2 = Object();
      PlayerProgressionService.blockDialogsFor(owner1);
      expect(PlayerProgressionService.dialogSafe.value, isFalse);
      PlayerProgressionService.blockDialogsFor(owner2);
      expect(PlayerProgressionService.dialogSafe.value, isFalse);
      PlayerProgressionService.unblockDialogsFor(owner1);
      expect(PlayerProgressionService.dialogSafe.value, isFalse,
          reason: 'owner2 هنوز blocker دارد');
      PlayerProgressionService.unblockDialogsFor(owner2);
      expect(PlayerProgressionService.dialogSafe.value, isTrue);
    });

    test('consume drains atomically', () async {
      await PlayerProgressionService.addXP(
        eventId: 't:c1',
        amount: PlayerProgressionService.cumulativeXP(2),
        source: 'test',
      );
      await PlayerProgressionService.addXP(
        eventId: 't:c2',
        amount: PlayerProgressionService.cumulativeXP(3) -
            PlayerProgressionService.cumulativeXP(2),
        source: 'test',
      );
      final batch = PlayerProgressionService.consumePendingLevelUps();
      expect(batch.length, 2);
      expect(PlayerProgressionService.pendingLevelUps.value, isEmpty);

      final second = PlayerProgressionService.consumePendingLevelUps();
      expect(second, isEmpty);
    });

    test('batch aggregates first oldLevel and last newLevel', () async {
      await PlayerProgressionService.addXP(
        eventId: 't:b1',
        amount: PlayerProgressionService.cumulativeXP(2),
        source: 'test',
      );
      await PlayerProgressionService.addXP(
        eventId: 't:b2',
        amount: PlayerProgressionService.cumulativeXP(3) -
            PlayerProgressionService.cumulativeXP(2),
        source: 'test',
      );
      final batch = PlayerProgressionService.consumePendingLevelUps();
      // تأیید aggregation: طول batch و first/last
      expect(batch.length, 2);
      expect(batch.first.oldLevel, 1);
      expect(batch.last.newLevel, 3);
      // L1 و L3 هر دو در بازهٔ beginner (L1–L4) هستند
      // → عنوان تغییر نمی‌کند (طبق تعریف Stage 1)
      expect(PlayerTitle.forLevel(batch.first.oldLevel), PlayerTitle.beginner);
      expect(PlayerTitle.forLevel(batch.last.newLevel), PlayerTitle.beginner);
    });
  });
}
