import 'package:an_tam_pharma/app/theme.dart';
import 'package:an_tam_pharma/features/auth/presentation/screens/login_screen.dart';
import 'package:an_tam_pharma/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PHAN 1 - PASS: Integration/E2E thay cho Selenium', () {
    testWidgets('E2E: Mo app va kiem tra man hinh dang nhap', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Số điện thoại hoặc email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
    });

    testWidgets('E2E: Bo trong form thi hien thi loi validate', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(
        find.text('Vui lòng nhập email hoặc số điện thoại'),
        findsOneWidget,
      );
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('E2E: Nhap du lieu va bat/tat hien mat khau', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại hoặc email'),
        '0332180384',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        '123456',
      );
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pumpAndSettle();

      expect(find.text('0332180384'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
    });
  });

  group('PHAN 2 - FAIL DEMO: Integration/E2E sai co chu dich', () {
    testWidgets('SAI: Mong muon co man hinh trang chu khi van o dang nhap', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Trang chủ'), findsOneWidget);
    });

    testWidgets('SAI: Bo trong form nhung lai mong khong co loi mat khau', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
    });
  });
}

Widget _buildTestApp() {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    ),
  );
}
