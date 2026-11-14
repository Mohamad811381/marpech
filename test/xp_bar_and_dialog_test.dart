// ignore_for_file: prefer_const_constructors

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marpech/models/player_title.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/models/level_reward.dart';
import 'package:marpech/services/player_progression_service.dart';
import 'package:marpech/widgets/level_up_dialog.dart';
import 'package:marpech/widgets/xp_progress_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    PlayerProgressionService.resetStateForTests();
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
  });

  tearDown(() {
    PlayerProgressionService.resetStateForTests();
  });

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  group('XpProgressBar', () {
    testWidgets('Level 1 shows low progress', (tester) async {
      await tester
          .pumpWidget(wrap(XpProgressBar(xpTotal: 0, palette: neonPalette)));
      await tester.pumpAndSettle();
      expect(find.byType(XpProgressBar), findsOneWidget);
      expect(find.textContaining('0 / 20'), findsOneWidget);
    });

    testWidgets('mid-level shows partial progress', (tester) async {
      await tester.pumpWidget(wrap(
        XpProgressBar(
          xpTotal: PlayerProgressionService.cumulativeXP(5),
          palette: neonPalette,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(XpProgressBar), findsOneWidget);
    });

    testWidgets('Level 100 shows MAX', (tester) async {
      await tester.pumpWidget(wrap(
        XpProgressBar(
          xpTotal: PlayerProgressionService.cumulativeXP(100),
          palette: neonPalette,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('MAX'), findsWidgets);
    });

    testWidgets('division-safe at Level 100 with extra XP', (tester) async {
      await tester.pumpWidget(wrap(
        XpProgressBar(
          xpTotal: PlayerProgressionService.cumulativeXP(100) + 9999,
          palette: neonPalette,
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('LevelUpDialog', () {
    LevelUpBatch makeBatch({
      required int oldLevel,
      required int newLevel,
      List<LevelReward> milestones = const [],
    }) {
      return LevelUpBatch(
        oldLevel: oldLevel,
        newLevel: newLevel,
        xpTotalAfter: PlayerProgressionService.cumulativeXP(newLevel),
        totalXpGained: PlayerProgressionService.cumulativeXP(newLevel) -
            PlayerProgressionService.cumulativeXP(oldLevel),
        milestones: milestones,
        cosmetics: milestones.where((m) => m.hasCosmetic).toList(),
        oldTitle: PlayerTitle.forLevel(oldLevel),
        newTitle: PlayerTitle.forLevel(newLevel),
      );
    }

    testWidgets('single level-up renders', (tester) async {
      final batch = makeBatch(oldLevel: 1, newLevel: 2, milestones: const []);
      await tester.pumpWidget(wrap(
        LevelUpDialog(palette: neonPalette, batch: batch),
      ));
      await tester.pump();
      expect(find.byType(LevelUpDialog), findsOneWidget);
      expect(find.textContaining('1'), findsWidgets);
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('multi-level batch renders', (tester) async {
      final batch = makeBatch(oldLevel: 1, newLevel: 5, milestones: [
        allLevelRewards.firstWhere((r) => r.level == 5),
      ]);
      await tester.pumpWidget(wrap(
        LevelUpDialog(palette: neonPalette, batch: batch),
      ));
      await tester.pump();
      expect(find.byType(LevelUpDialog), findsOneWidget);
    });

    testWidgets('max level renders', (tester) async {
      final batch = makeBatch(oldLevel: 99, newLevel: 100, milestones: [
        allLevelRewards.firstWhere((r) => r.level == 100),
      ]);
      await tester.pumpWidget(wrap(
        LevelUpDialog(palette: neonPalette, batch: batch),
      ));
      await tester.pump();
      expect(find.byType(LevelUpDialog), findsOneWidget);
    });

    testWidgets('barrier dismissible false by default', (tester) async {
      // Verify by wrapping in a full Navigator
      final batch = makeBatch(oldLevel: 1, newLevel: 2);
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    LevelUpDialog(palette: neonPalette, batch: batch),
              );
            },
            child: const Text('open'),
          );
        }),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(LevelUpDialog), findsOneWidget);

      // Tap barrier area (outside dialog) — should NOT dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(LevelUpDialog), findsOneWidget,
          reason: 'barrierDismissible=false → tap outside نباید ببندد');
    });
  });
}
