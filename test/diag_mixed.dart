import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unit before widget', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
  });

  testWidgets('widget after unit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    expect(true, isTrue);
  });
}
