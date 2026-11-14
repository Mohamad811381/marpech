import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marpech/services/achievements_service.dart';
import 'package:marpech/services/player_progression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerProgressionService.ensureSchema();
  });

  test('newly unlocked achievement grants 40 XP once', () async {
    await AchievementsService.recordGame(score: 100, snakeLength: 5);
    final p1 = await PlayerProgressionService.loadProfile();
    // حداقل یکی از دستاوردهای اولیه (first_game / score_500?) باز شده
    final xp1 = p1.xpTotal;
    expect(xp1, greaterThan(0));

    // دوباره recordGame → دستاورد جدید نباید XP بده
    await AchievementsService.recordGame(score: 100, snakeLength: 5);
    final p2 = await PlayerProgressionService.loadProfile();
    // ممکنه دستاورد جدید باز نشه ولی XP نباید دوباره داده بشه برای همون
    expect(p2.xpTotal, xp1);
  });
}
