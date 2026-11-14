// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marpech/widgets/daily_reward_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/screens/main_shell.dart';
import 'package:marpech/services/player_progression_service.dart';
import 'package:marpech/widgets/level_up_dialog.dart';
import 'package:marpech/services/daily_reward_service.dart';

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
    await DailyRewardService.markAutoShown();
  });

  tearDown(() {
    PlayerProgressionService.resetStateForTests();
  });

  void registerCleanup(WidgetTester tester) {
    addTearDown(() async {
      Object? unmountError;
      StackTrace? unmountStack;
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } catch (e, st) {
        unmountError = e;
        unmountStack = st;
      }
      final hasPendingLeak =
          PlayerProgressionService.pendingLevelUps.debugHasListeners;
      final hasSafeLeak = PlayerProgressionService.dialogSafe.debugHasListeners;
      final hasLeak = hasPendingLeak || hasSafeLeak;

      if (unmountError != null && hasLeak) {
        Error.throwWithStackTrace(
          StateError(
            'Unmount failed AND listener leaked '
            '(pending=$hasPendingLeak, safe=$hasSafeLeak). '
            'State NOT reset. Original: $unmountError.',
          ),
          unmountStack!,
        );
      }
      if (unmountError != null) {
        Error.throwWithStackTrace(unmountError, unmountStack!);
      }
      if (hasLeak) {
        fail('Listener leaked after unmount '
            '(pending=$hasPendingLeak, safe=$hasSafeLeak). '
            'State NOT reset.');
      }
    });
  }

  Future<void> tapDialogOk(WidgetTester tester) async {
    final okButton = find.descendant(
      of: find.byType(LevelUpDialog),
      matching: find.byType(ElevatedButton),
    );
    expect(okButton, findsOneWidget,
        reason: 'OK button not found inside LevelUpDialog');
    await tester.tap(okButton);
  }

  Future<void> mountShell(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('single level-up → dialog appears', (tester) async {
    registerCleanup(tester);
    await mountShell(tester);
    expect(find.byType(LevelUpDialog), findsNothing);

    await PlayerProgressionService.addXP(
      eventId: 'c:1',
      amount: PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(LevelUpDialog), findsOneWidget);
    await tapDialogOk(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpDialog), findsNothing);
  });

  testWidgets('second event while dialog open → not lost', (tester) async {
    registerCleanup(tester);
    await mountShell(tester);

    await PlayerProgressionService.addXP(
      eventId: 'c:2a',
      amount: PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpDialog), findsOneWidget);

    // Enqueue دومین رویداد در حالی که دیالوگ اول باز است
    await PlayerProgressionService.addXP(
      eventId: 'c:2b',
      amount: PlayerProgressionService.cumulativeXP(3) -
          PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );

    // بستن دیالوگ اول
    await tapDialogOk(tester);
    await tester.pumpAndSettle();

    // دیالوگ دوم باید ظاهر شود
    expect(find.byType(LevelUpDialog), findsOneWidget,
        reason: 'رویداد دوم نباید گم شود');

    await tapDialogOk(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpDialog), findsNothing);
  });

  testWidgets('blocked: 3 events accumulate → 1 aggregate dialog',
      (tester) async {
    registerCleanup(tester);
    await mountShell(tester);

    final blocker = Object();
    PlayerProgressionService.blockDialogsFor(blocker);

    await PlayerProgressionService.addXP(
      eventId: 'c:3a',
      amount: PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );
    await PlayerProgressionService.addXP(
      eventId: 'c:3b',
      amount: PlayerProgressionService.cumulativeXP(3) -
          PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );
    await PlayerProgressionService.addXP(
      eventId: 'c:3c',
      amount: PlayerProgressionService.cumulativeXP(4) -
          PlayerProgressionService.cumulativeXP(3),
      source: 'game',
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(LevelUpDialog), findsNothing);
    expect(PlayerProgressionService.pendingLevelUps.value.length, 3);

    PlayerProgressionService.unblockDialogsFor(blocker);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(LevelUpDialog), findsOneWidget);
    expect(PlayerProgressionService.pendingLevelUps.value, isEmpty);

    await tapDialogOk(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpDialog), findsNothing);
  });

  testWidgets('blocker prevents dialog until unblock', (tester) async {
    registerCleanup(tester);
    await mountShell(tester);

    final blocker = Object();
    PlayerProgressionService.blockDialogsFor(blocker);

    await PlayerProgressionService.addXP(
      eventId: 'c:4',
      amount: PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LevelUpDialog), findsNothing);
    expect(PlayerProgressionService.pendingLevelUps.value.length, 1);

    PlayerProgressionService.unblockDialogsFor(blocker);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpDialog), findsOneWidget);

    await tapDialogOk(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('race: blocker added between schedule and pump', (tester) async {
    registerCleanup(tester);
    await mountShell(tester);

    await PlayerProgressionService.addXP(
      eventId: 'race:1',
      amount: PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );
    expect(PlayerProgressionService.pendingLevelUps.value.length, 1);

    final blocker = Object();
    PlayerProgressionService.blockDialogsFor(blocker);
    expect(PlayerProgressionService.dialogSafe.value, isFalse);

    await tester.pump();
    expect(find.byType(LevelUpDialog), findsNothing);
    expect(PlayerProgressionService.pendingLevelUps.value.length, 1,
        reason: 'blocked callback نباید consume کند');

    PlayerProgressionService.unblockDialogsFor(blocker);
    expect(PlayerProgressionService.dialogSafe.value, isTrue);

    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpDialog), findsOneWidget);
    expect(PlayerProgressionService.pendingLevelUps.value, isEmpty);

    await tapDialogOk(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('both dialogs never show simultaneously', (tester) async {
    registerCleanup(tester);
    // Override setUp: allow auto-show reward
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
    // (markAutoShown صدا زده نمی‌شود → reward در دسترس است)

    // Mount بدون mountShell تا timer 700ms فرصت اجرا داشته باشد
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Reward dialog باید auto-show شده باشد
    expect(find.byType(DailyRewardDialog), findsOneWidget,
        reason: 'reward باید auto-show شود');
    expect(find.byType(LevelUpDialog), findsNothing);

    // Enqueue level-up در حالی که reward باز است
    await PlayerProgressionService.addXP(
      eventId: 'coexist:1',
      amount: PlayerProgressionService.cumulativeXP(2),
      source: 'game',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Level-up نباید نشان داده شود (توسط reward defer شده)
    expect(find.byType(DailyRewardDialog), findsOneWidget);
    expect(find.byType(LevelUpDialog), findsNothing,
        reason: 'level-up نباید هم‌زمان با reward باز شود');
    expect(PlayerProgressionService.pendingLevelUps.value.length, 1,
        reason: 'رویداد level-up باید در صف بماند');
  });
}
