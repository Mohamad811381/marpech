import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/models/game_settings.dart';
import 'package:marpech/services/player_progression_service.dart';
import 'package:marpech/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    PlayerProgressionService.resetStateForTests();
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
    await SettingsService.save(const GameSettings(
      sfx: false, music: false, haptics: false,
    ));
  });

  testWidgets('test A: addXP مستقیم در testWidgets', (tester) async {
    debugPrint('🟢 A1: before addXP');
    await PlayerProgressionService.addXP(
      eventId: 'diag:a',
      amount: PlayerProgressionService.cumulativeXP(5),
      source: 'game',
    );
    debugPrint('✅ A2: after addXP');
    expect(1, 1);
  });

  testWidgets('test B: addXP داخل runAsync', (tester) async {
    debugPrint('🟢 B1: before runAsync');
    await tester.runAsync(() async {
      await PlayerProgressionService.addXP(
        eventId: 'diag:b',
        amount: PlayerProgressionService.cumulativeXP(5),
        source: 'game',
      );
    });
    debugPrint('✅ B2: after runAsync');
    expect(1, 1);
  });
}