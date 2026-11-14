import 'package:flutter_test/flutter_test.dart';
import 'package:marpech/app.dart';

void main() {
  testWidgets('MarpechApp renders without crashing', (tester) async {
    await tester.pumpWidget(const MarpechApp());

    // فریم اول
    await tester.pump();

    // اجازه بده SharedPreferences (mock) لود بشه
    await tester.pump(const Duration(milliseconds: 100));

    // فقط تأیید کن که ویجت رندر شده
    expect(find.byType(MarpechApp), findsOneWidget);

    // ✅ تموم — بدون pumpAndSettle
  });
}
