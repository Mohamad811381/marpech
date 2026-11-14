import 'package:flutter/material.dart';
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
      sfx: false, music: false, haptics: false,
    ));
  });

  testWidgets('DIAG A: minimal widget', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('DIAG B: MaterialApp + Text', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('hi'))));
  });

  testWidgets('DIAG C: full LevelUpDialog', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });

    await PlayerProgressionService.addXP(
      eventId: 'diag:1',
      amount: PlayerProgressionService.cumulativeXP(5),
      source: 'game',
    );

    final results = PlayerProgressionService.consumePendingLevelUps();

    final xpTotal = await _getXpTotal();

    final batch = LevelUpBatch.fromResults(results, xpTotal);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LevelUpDialog(palette: neonPalette, batch: batch)),
    ));

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 500));

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LevelUpDialog), findsOneWidget);
  });
}

Future<int> _getXpTotal() async {
  final p = await SharedPreferences.getInstance();
  return p.getInt('player_xp_total') ?? 0;
}