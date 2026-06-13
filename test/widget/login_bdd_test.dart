import 'package:doan/app/theme.dart';
import 'package:doan/features/auth/presentation/screens/login_screen.dart';
import 'package:doan/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('PHAN 1 - PASS: BDD/Gherkin style cho man hinh dang nhap', () {
    testWidgets(
      'Scenario: Nguoi dung mo man hinh dang nhap thi thay day du thanh phan',
      (tester) async {
        // Given nguoi dung dang o man hinh dang nhap
        await tester.pumpWidget(_buildLoginScreen());

        // Then he thong hien thi day du cac thanh phan chinh
        expect(find.text('Đăng nhập'), findsWidgets);
        expect(find.text('Số điện thoại hoặc email'), findsOneWidget);
        expect(find.text('Mật khẩu'), findsOneWidget);
        expect(find.text('Quên mật khẩu?'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -450));
        await tester.pumpAndSettle();

        expect(find.text('Đăng ký ngay'), findsOneWidget);
      },
    );

    testWidgets('Scenario: Bo trong form dang nhap thi hien thi loi validate', (
      tester,
    ) async {
      // Given nguoi dung dang o man hinh dang nhap
      await tester.pumpWidget(_buildLoginScreen());

      // When nguoi dung bam nut Dang nhap nhung chua nhap du lieu
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();

      // Then he thong hien thi loi bat buoc nhap tai khoan va mat khau
      expect(
        find.text('Vui lòng nhập email hoặc số điện thoại'),
        findsOneWidget,
      );
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets(
      'Scenario: Bam icon con mat thi doi trang thai hien/an mat khau',
      (tester) async {
        // Given nguoi dung dang o man hinh dang nhap
        await tester.pumpWidget(_buildLoginScreen());

        // Then ban dau nut co tooltip Hien mat khau
        expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
        expect(find.byTooltip('Ẩn mật khẩu'), findsNothing);

        // When nguoi dung bam icon con mat
        await tester.tap(find.byTooltip('Hiện mật khẩu'));
        await tester.pump();

        // Then tooltip doi thanh An mat khau
        expect(find.byTooltip('Hiện mật khẩu'), findsNothing);
        expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
      },
    );
  });

  group('PHAN 2 - BDD/Gherkin style bo sung', () {
    testWidgets('Scenario: Man hinh dang nhap khong hien nut Dang xuat', (
      tester,
    ) async {
      // Given nguoi dung dang o man hinh dang nhap
      await tester.pumpWidget(_buildLoginScreen());

      // Then he thong khong hien nut dang xuat
      expect(find.text('Đăng xuất'), findsNothing);
    });

    testWidgets('Scenario: Bo trong form thi hien thi loi validate', (
      tester,
    ) async {
      // Given nguoi dung dang o man hinh dang nhap
      await tester.pumpWidget(_buildLoginScreen());

      // When nguoi dung bam nut Dang nhap nhung chua nhap du lieu
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();

      // Then he thong hien thi loi validate
      expect(
        find.text('Vui lòng nhập email hoặc số điện thoại'),
        findsOneWidget,
      );
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });
  });
}

Widget _buildLoginScreen() {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    ),
  );
}
