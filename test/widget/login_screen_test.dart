import 'package:doan/app/routes.dart';
import 'package:doan/app/theme.dart';
import 'package:doan/core/storage/token_storage.dart';
import 'package:doan/features/auth/data/models/user_model.dart';
import 'package:doan/features/auth/data/services/auth_service.dart';
import 'package:doan/features/auth/data/services/google_auth_service.dart';
import 'package:doan/features/auth/presentation/screens/login_screen.dart';
import 'package:doan/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('LoginScreen Widget Test', () {
    testWidgets('hiển thị nút đăng nhập Google và semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(_buildLoginScreen());

      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Số điện thoại hoặc email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);

      await _scrollToGoogleButton(tester);

      expect(find.text('Hoặc tiếp tục với'), findsOneWidget);
      expect(find.text('Đăng nhập với Google'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Đăng nhập bằng tài khoản Google'),
        findsOneWidget,
      );
      expect(find.text('Đăng ký ngay'), findsOneWidget);
    });

    testWidgets('bỏ trống form thì hiển thị lỗi validate', (tester) async {
      await tester.pumpWidget(_buildLoginScreen());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();

      expect(
        find.text('Vui lòng nhập email hoặc số điện thoại'),
        findsOneWidget,
      );
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('khi isGoogleLoading true thì nút bị disable và có loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildLoginScreen(provider: _FakeAuthProvider(isGoogleLoading: true)),
      );

      await _scrollToGoogleButton(tester);

      expect(find.text('Đang đăng nhập...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Đang đăng nhập...'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Google login CUSTOMER thành công điều hướng main', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildLoginScreen(
          provider: _FakeAuthProvider(
            googleLoginResult: true,
            user: const UserModel(id: 'customer-1', roles: ['CUSTOMER']),
          ),
        ),
      );

      await _tapGoogleLogin(tester);

      expect(find.byKey(const ValueKey('main-route')), findsOneWidget);
    });

    testWidgets('Google login ADMIN thành công điều hướng admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildLoginScreen(
          provider: _FakeAuthProvider(
            googleLoginResult: true,
            user: const UserModel(id: 'admin-1', roles: ['ROLE_ADMIN']),
          ),
        ),
      );

      await _tapGoogleLogin(tester);

      expect(find.byKey(const ValueKey('admin-route')), findsOneWidget);
    });

    testWidgets('người dùng hủy Google login thì không hiển thị lỗi đỏ', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildLoginScreen(
          provider: _FakeAuthProvider(googleLoginResult: false),
        ),
      );

      await _tapGoogleLogin(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('Google'), findsOneWidget);
    });

    testWidgets('backend lỗi Google login thì hiển thị message tiếng Việt', (
      tester,
    ) async {
      const message = 'Tài khoản Google không hợp lệ hoặc đã hết hạn';
      await tester.pumpWidget(
        _buildLoginScreen(
          provider: _FakeAuthProvider(
            googleLoginResult: false,
            googleLoginError: message,
          ),
        ),
      );

      await _tapGoogleLogin(tester);

      expect(find.text(message), findsWidgets);
    });
  });
}

Future<void> _scrollToGoogleButton(WidgetTester tester) async {
  final idleButton = find.text('Đăng nhập với Google');
  final loadingButton = find.text('Đang đăng nhập...');
  await tester.ensureVisible(
    idleButton.evaluate().isNotEmpty ? idleButton : loadingButton,
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tapGoogleLogin(WidgetTester tester) async {
  await _scrollToGoogleButton(tester);
  await tester.tap(find.text('Đăng nhập với Google'));
  await tester.pumpAndSettle();
}

Widget _buildLoginScreen({_FakeAuthProvider? provider}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider ?? _FakeAuthProvider(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.main: (_) =>
            const Scaffold(body: SizedBox(key: ValueKey('main-route'))),
        AppRoutes.admin: (_) =>
            const Scaffold(body: SizedBox(key: ValueKey('admin-route'))),
        AppRoutes.pharmacist: (_) =>
            const Scaffold(body: SizedBox(key: ValueKey('pharmacist-route'))),
      },
      home: const LoginScreen(),
    ),
  );
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider({
    bool isGoogleLoading = false,
    bool googleLoginResult = false,
    String? googleLoginError,
    UserModel? user,
  }) : _isGoogleLoading = isGoogleLoading,
       _googleLoginResult = googleLoginResult,
       _googleLoginError = googleLoginError,
       _user = user,
       super(
         authService: _NoopAuthService(),
         googleAuthService: _NoopGoogleAuthService(),
         tokenStorage: _NoopTokenStorage(),
       );

  final bool _isGoogleLoading;
  final bool _googleLoginResult;
  final String? _googleLoginError;
  final UserModel? _user;

  @override
  bool get isGoogleLoading => _isGoogleLoading;

  @override
  String? get googleLoginError => _googleLoginError;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<bool> loginWithGoogle() async => _googleLoginResult;
}

class _NoopAuthService extends AuthService {}

class _NoopGoogleAuthService extends GoogleAuthService {
  @override
  Future<void> dispose() async {}
}

class _NoopTokenStorage extends TokenStorage {}
