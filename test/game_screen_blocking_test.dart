// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/services/player_progression_service.dart';

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

  testWidgets('blockDialogsFor blocks; unblockDialogsFor releases',
      (tester) async {
    final owner = Object();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          return TextButton(
            onPressed: () {
              PlayerProgressionService.blockDialogsFor(owner);
            },
            child: const Text('block'),
          );
        }),
      ),
    );

    expect(PlayerProgressionService.dialogSafe.value, isTrue);
    await tester.tap(find.text('block'));
    await tester.pump();
    expect(PlayerProgressionService.dialogSafe.value, isFalse);

    PlayerProgressionService.unblockDialogsFor(owner);
    await tester.pump();
    expect(PlayerProgressionService.dialogSafe.value, isTrue);
  });

  testWidgets('two owners — releasing one keeps unsafe', (tester) async {
    final ownerA = Object();
    final ownerB = Object();
    PlayerProgressionService.blockDialogsFor(ownerA);
    PlayerProgressionService.blockDialogsFor(ownerB);
    expect(PlayerProgressionService.dialogSafe.value, isFalse);

    PlayerProgressionService.unblockDialogsFor(ownerA);
    expect(PlayerProgressionService.dialogSafe.value, isFalse,
        reason: 'ownerB هنوز blocker دارد');

    PlayerProgressionService.unblockDialogsFor(ownerB);
    expect(PlayerProgressionService.dialogSafe.value, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}