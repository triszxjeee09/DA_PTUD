import 'package:doan/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hiển thị màn hình splash', (WidgetTester tester) async {
    await tester.pumpWidget(const PharmaApp());

    expect(find.text('An Tâm Pharma'), findsOneWidget);
    expect(
      find.text('Mua thuốc an tâm, chăm sóc sức khỏe mỗi ngày'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  });
}
