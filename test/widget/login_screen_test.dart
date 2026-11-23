import 'package:an_tam_pharma/app/theme.dart';
import 'package:an_tam_pharma/features/auth/presentation/screens/login_screen.dart';
import 'package:an_tam_pharma/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('login form uses email and password only', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Số điện thoại hoặc email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('failed login displays one inline message', (tester) async {
    final authProvider = _FailingAuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'wrong@email.test',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    final submitButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(
      find.text('Email/tài khoản hoặc mật khẩu không đúng'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });
}

class _FailingAuthProvider extends AuthProvider {
  String? _message;

  @override
  String? get errorMessage => _message;

  @override
  Future<bool> login(String username, String password) async {
    _message = 'Email/tài khoản hoặc mật khẩu không đúng';
    notifyListeners();
    return false;
  }
}
