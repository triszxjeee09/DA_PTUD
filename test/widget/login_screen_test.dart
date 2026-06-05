import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doan/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Test', () {
    testWidgets('PASS: Hiển thị đầy đủ giao diện đăng nhập', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Số điện thoại hoặc email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Đăng ký ngay'), findsOneWidget);
    });

    testWidgets('PASS: Bỏ trống form thì hiển thị lỗi validate', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');

      await tester.tap(loginButton);
      await tester.pump();

      expect(
        find.text('Vui lòng nhập email hoặc số điện thoại'),
        findsOneWidget,
      );

      expect(
        find.text('Vui lòng nhập mật khẩu'),
        findsOneWidget,
      );
    });
  });
}