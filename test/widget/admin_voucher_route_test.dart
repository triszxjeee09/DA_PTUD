import 'package:doan/app/routes.dart';
import 'package:doan/app/theme.dart';
import 'package:doan/core/storage/token_storage.dart';
import 'package:doan/features/admin/data/models/admin_voucher_model.dart';
import 'package:doan/features/admin/providers/admin_voucher_provider.dart';
import 'package:doan/features/auth/data/models/user_model.dart';
import 'package:doan/features/auth/data/services/auth_service.dart';
import 'package:doan/features/auth/data/services/google_auth_service.dart';
import 'package:doan/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('route form voucher nhận được pushNamed<bool>', (tester) async {
    final voucherProvider = _FakeAdminVoucherProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminVoucherProvider>.value(
            value: voucherProvider,
          ),
          ChangeNotifierProvider<AuthProvider>.value(
            value: _FakeAuthProvider(
              currentUser: const UserModel(
                id: 'admin-1',
                roles: ['ROLE_ADMIN'],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamed<bool>(AppRoutes.adminVoucherForm);
                      },
                      child: const Text('Thêm voucher'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed<bool>(
                          AppRoutes.adminVoucherForm,
                          arguments: {'voucherId': 'voucher-1'},
                        );
                      },
                      child: const Text('Sửa voucher'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Thêm voucher'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm voucher'), findsWidgets);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sửa voucher'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa voucher'), findsOneWidget);
    expect(voucherProvider.loadVoucherDetailCount, 1);
  });
}

class _FakeAdminVoucherProvider extends AdminVoucherProvider {
  int loadVoucherDetailCount = 0;

  @override
  AdminVoucherModel? get selectedVoucher => AdminVoucherModel(
    id: 'voucher-1',
    code: 'SALE10',
    name: 'Sale 10%',
    discountType: 'PERCENT',
    discountValue: 10,
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 6, 30),
  );

  @override
  bool get isLoadingDetail => false;

  @override
  bool get isSubmitting => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> loadVoucherDetail(String id) async {
    loadVoucherDetailCount += 1;
  }
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider({required UserModel currentUser})
    : _currentUser = currentUser,
      super(
        authService: _NoopAuthService(),
        googleAuthService: _NoopGoogleAuthService(),
        tokenStorage: _NoopTokenStorage(),
      );

  final UserModel _currentUser;

  @override
  UserModel? get currentUser => _currentUser;
}

class _NoopAuthService extends AuthService {}

class _NoopGoogleAuthService extends GoogleAuthService {
  @override
  Future<void> dispose() async {}
}

class _NoopTokenStorage extends TokenStorage {}
