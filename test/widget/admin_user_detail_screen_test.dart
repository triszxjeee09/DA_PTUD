import 'package:an_tam_pharma/app/theme.dart';
import 'package:an_tam_pharma/app/routes.dart';
import 'package:an_tam_pharma/core/storage/token_storage.dart';
import 'package:an_tam_pharma/features/admin/data/models/admin_user_model.dart';
import 'package:an_tam_pharma/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:an_tam_pharma/features/admin/providers/admin_user_provider.dart';
import 'package:an_tam_pharma/features/auth/data/models/user_model.dart';
import 'package:an_tam_pharma/features/auth/data/services/auth_service.dart';
import 'package:an_tam_pharma/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('AdminUserDetailScreen Widget Test', () {
    testWidgets('hiển thị loading', (tester) async {
      await tester.pumpWidget(
        _buildScreen(adminProvider: _FakeAdminUserProvider(isLoading: true)),
      );

      expect(find.text('Đang tải người dùng...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hiển thị thông tin user', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          adminProvider: _FakeAdminUserProvider(user: _sampleUser()),
        ),
      );
      await tester.pump();

      expect(find.text('Chi tiết người dùng'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsWidgets);
      expect(find.text('user@example.com'), findsWidgets);
      expect(find.text('Thông tin tài khoản'), findsOneWidget);
      expect(find.text('Tài khoản thường'), findsOneWidget);
    });

    testWidgets('ACTIVE có nút Khóa tài khoản', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          adminProvider: _FakeAdminUserProvider(
            user: _sampleUser(status: 'ACTIVE'),
          ),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Khóa tài khoản'), 360);

      expect(find.text('Khóa tài khoản'), findsWidgets);
    });

    testWidgets('BLOCKED có nút Mở khóa tài khoản', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          adminProvider: _FakeAdminUserProvider(
            user: _sampleUser(status: 'BLOCKED'),
          ),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Mở khóa tài khoản'), 360);

      expect(find.text('Mở khóa tài khoản'), findsWidgets);
    });

    testWidgets('bấm Gán vai trò mở bottom sheet', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          adminProvider: _FakeAdminUserProvider(user: _sampleUser()),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Gán vai trò'), 360);
      await tester.ensureVisible(find.text('Gán vai trò'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gán vai trò'));
      await tester.pumpAndSettle();

      expect(find.text('Khách hàng'), findsWidgets);
      expect(find.text('Dược sĩ'), findsOneWidget);
      expect(find.text('Quản trị viên'), findsWidgets);
    });

    testWidgets('bấm Đặt lại mật khẩu mở dialog', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          adminProvider: _FakeAdminUserProvider(user: _sampleUser()),
        ),
      );
      await tester.pump();

      final button = find.widgetWithText(OutlinedButton, 'Đặt lại mật khẩu');
      await tester.scrollUntilVisible(find.text('Đặt lại mật khẩu'), 360);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    });

    testWidgets('user hiện tại không thể tự khóa', (tester) async {
      final user = _sampleUser(status: 'ACTIVE', roles: const ['ROLE_ADMIN']);
      await tester.pumpWidget(
        _buildScreen(
          adminProvider: _FakeAdminUserProvider(user: user),
          currentUser: UserModel(id: user.id, roles: const ['ROLE_ADMIN']),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Khóa tài khoản'), 360);

      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Khóa tài khoản'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(
        find.text(
          'Bạn không thể thực hiện thao tác này trên tài khoản của chính mình',
        ),
        findsWidgets,
      );
    });

    testWidgets('API lỗi hiển thị error', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          adminProvider: _FakeAdminUserProvider(
            errorMessage: 'Không tìm thấy người dùng',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Không tìm thấy người dùng'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('route detail nhận được pushNamed<bool>', (tester) async {
      final adminProvider = _FakeAdminUserProvider(user: _sampleUser());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminUserProvider>.value(
              value: adminProvider,
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
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed<bool>(
                        AppRoutes.adminUserDetail,
                        arguments: {'userId': 'user-1'},
                      );
                    },
                    child: const Text('Mở chi tiết'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở chi tiết'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết người dùng'), findsOneWidget);
      expect(adminProvider.loadUserDetailCount, 1);
    });
  });
}

Widget _buildScreen({
  required _FakeAdminUserProvider adminProvider,
  UserModel? currentUser,
}) {
  final userId = adminProvider.selectedUser?.id ?? 'user-1';

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdminUserProvider>.value(value: adminProvider),
      ChangeNotifierProvider<AuthProvider>.value(
        value: _FakeAuthProvider(
          currentUser:
              currentUser ??
              const UserModel(id: 'admin-1', roles: ['ROLE_ADMIN']),
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AdminUserDetailScreen(userId: userId),
    ),
  );
}

AdminUserModel _sampleUser({
  String id = 'user-1',
  String status = 'ACTIVE',
  List<String> roles = const ['CUSTOMER'],
}) {
  return AdminUserModel(
    id: id,
    username: 'nguyenvana',
    fullName: 'Nguyễn Văn A',
    email: 'user@example.com',
    phone: '0909000000',
    gender: 'MALE',
    dateOfBirth: '1995-01-02',
    authProvider: 'LOCAL',
    status: status,
    roles: roles,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
}

class _FakeAdminUserProvider extends AdminUserProvider {
  _FakeAdminUserProvider({
    AdminUserModel? user,
    bool isLoading = false,
    String? errorMessage,
  }) : _user = user,
       _isLoading = isLoading,
       _errorMessage = errorMessage;

  final AdminUserModel? _user;
  final bool _isLoading;
  final String? _errorMessage;

  int loadUserDetailCount = 0;

  @override
  AdminUserModel? get selectedUser => _user;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isUpdatingStatus => false;

  @override
  bool get isUpdatingRole => false;

  @override
  bool get isBlockingUser => false;

  @override
  bool get isUnlockingUser => false;

  @override
  bool get isAssigningRole => false;

  @override
  bool get isRemovingRole => false;

  @override
  bool get isResettingPassword => false;

  @override
  bool get isDeactivatingUser => false;

  @override
  Future<void> loadUserDetail(String userId) async {
    loadUserDetailCount += 1;
  }

  @override
  Future<bool> blockUser(String userId) async => true;

  @override
  Future<bool> unlockUser(String userId) async => true;

  @override
  Future<bool> assignRole(String userId, String roleName) async => true;

  @override
  Future<bool> removeRole(String userId, String roleName) async => true;

  @override
  Future<bool> resetPassword(
    String userId,
    String newPassword,
    String confirmPassword,
  ) async {
    return true;
  }

  @override
  Future<bool> deactivateUser(String userId) async => true;
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider({required UserModel currentUser})
    : _currentUser = currentUser,
      super(
        authService: _NoopAuthService(),
        tokenStorage: _NoopTokenStorage(),
      );

  final UserModel _currentUser;

  @override
  UserModel? get currentUser => _currentUser;
}

class _NoopAuthService extends AuthService {}

class _NoopTokenStorage extends TokenStorage {}
