import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/models/game_palette.dart';
import 'package:marpech/models/game_settings.dart';
import 'package:marpech/services/player_progression_service.dart';
import 'package:marpech/services/settings_service.dart';
import 'package:marpech/widgets/level_up_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock همهٔ audioplayers MethodChannels — جلوگیری از hang
  setUpAll(() {
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final ch in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.eventStream',
      'xyz.luan/audioplayers/marpech_sfx',
      'xyz.luan/audioplayers/marpech_music',
      'xyz.luan/audioplayers/events/marpech_sfx',
      'xyz.luan/audioplayers/events/marpech_music',
    ]) {
      m.setMockMethodCallHandler(MethodChannel(ch), (call) async => 1);
    }
    m.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  setUp(() async {
    PlayerProgressionService.resetStateForTests();
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
    await SettingsService.save(const GameSettings(
      sfx: false,
      music: false,
      haptics: false,
    ));
  });

  testWidgets('renders 5 level chips and total XP', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });

    await PlayerProgressionService.addXP(
      eventId: 'ui:1',
      amount: PlayerProgressionService.cumulativeXP(5),
      source: 'game',
    );
    final results = PlayerProgressionService.consumePendingLevelUps();
    final xp =
        (await SharedPreferences.getInstance()).getInt('player_xp_total') ?? 0;
    final batch = LevelUpBatch.fromResults(results, xp);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LevelUpDialog(palette: neonPalette, batch: batch),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LevelUpDialog), findsOneWidget);
    for (final lv in [1, 2, 3, 4, 5]) {
      expect(
        find.descendant(
          of: find.byType(LevelUpDialog),
          matching: find.text('Lv.$lv'),
        ),
        findsWidgets,
      );
    }
    expect(
      find.descendant(
        of: find.byType(LevelUpDialog),
        matching: find.textContaining('144'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(LevelUpDialog),
        matching: find.textContaining('30'),
      ),
      findsWidgets,
    );
  });

  testWidgets('long path collapses middle', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });

    await PlayerProgressionService.addXP(
      eventId: 'ui:2',
      amount: PlayerProgressionService.cumulativeXP(27),
      source: 'game',
    );
    final results = PlayerProgressionService.consumePendingLevelUps();
    final xp =
        (await SharedPreferences.getInstance()).getInt('player_xp_total') ?? 0;
    final batch = LevelUpBatch.fromResults(results, xp);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LevelUpDialog(palette: neonPalette, batch: batch),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(batch.levelPath.length, 27);
    expect(
      find.descendant(
        of: find.byType(LevelUpDialog),
        matching: find.text('...'),
      ),
      findsOneWidget,
    );
    expect(find.text('Lv.1'), findsWidgets);
    expect(find.text('Lv.2'), findsWidgets);
  });
}
