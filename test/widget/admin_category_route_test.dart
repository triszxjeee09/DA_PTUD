import 'package:an_tam_pharma/app/routes.dart';
import 'package:an_tam_pharma/app/theme.dart';
import 'package:an_tam_pharma/core/storage/token_storage.dart';
import 'package:an_tam_pharma/features/admin/data/models/admin_category_model.dart';
import 'package:an_tam_pharma/features/admin/providers/admin_category_provider.dart';
import 'package:an_tam_pharma/features/auth/data/models/user_model.dart';
import 'package:an_tam_pharma/features/auth/data/services/auth_service.dart';
import 'package:an_tam_pharma/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('route form danh mục nhận được pushNamed<bool>', (tester) async {
    final categoryProvider = _FakeAdminCategoryProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminCategoryProvider>.value(
            value: categoryProvider,
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
                        ).pushNamed<bool>(AppRoutes.adminCategoryForm);
                      },
                      child: const Text('Thêm danh mục'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed<bool>(
                          AppRoutes.adminCategoryForm,
                          arguments: {'categoryId': 'category-1'},
                        );
                      },
                      child: const Text('Sửa danh mục'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Thêm danh mục'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm danh mục'), findsWidgets);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sửa danh mục'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa danh mục'), findsOneWidget);
    expect(categoryProvider.loadCategoryDetailCount, 1);
  });
}

class _FakeAdminCategoryProvider extends AdminCategoryProvider {
  int loadCategoryDetailCount = 0;

  @override
  List<AdminCategoryModel> get categories => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingDetail => false;

  @override
  bool get isSubmitting => false;

  @override
  String? get errorMessage => null;

  @override
  AdminCategoryModel? get selectedCategory => const AdminCategoryModel(
    id: 'category-1',
    name: 'Vitamin',
    slug: 'vitamin',
  );

  @override
  Future<void> loadCategories({
    bool refresh = false,
    String? keyword,
    bool? isActive,
  }) async {}

  @override
  Future<void> loadCategoryDetail(String id) async {
    loadCategoryDetailCount += 1;
  }
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
