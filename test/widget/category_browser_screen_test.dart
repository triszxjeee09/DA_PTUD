import 'package:an_tam_pharma/app/theme.dart';
import 'package:an_tam_pharma/features/category/data/models/category_model.dart';
import 'package:an_tam_pharma/features/category/presentation/screens/category_browser_screen.dart';
import 'package:an_tam_pharma/features/category/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows and filters active categories', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<CategoryProvider>.value(
        value: _FakeCategoryProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CategoryBrowserScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Thuốc không kê đơn'), findsOneWidget);
    expect(find.text('Vitamin và thực phẩm bảo vệ sức khỏe'), findsOneWidget);
    expect(find.text('Danh mục đã ẩn'), findsNothing);

    await tester.enterText(find.byType(TextField), 'vitamin');
    await tester.pump();

    expect(find.text('Thuốc không kê đơn'), findsNothing);
    expect(find.text('Vitamin và thực phẩm bảo vệ sức khỏe'), findsOneWidget);
  });
}

class _FakeCategoryProvider extends CategoryProvider {
  @override
  List<CategoryModel> get categories => const [
    CategoryModel(
      id: 'category-001',
      name: 'Thuốc không kê đơn',
      slug: 'thuoc-khong-ke-don',
    ),
    CategoryModel(
      id: 'category-002',
      name: 'Vitamin và thực phẩm bảo vệ sức khỏe',
      slug: 'vitamin',
    ),
    CategoryModel(
      id: 'category-003',
      name: 'Danh mục đã ẩn',
      slug: 'hidden',
      isActive: false,
    ),
  ];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> loadCategories() async {}
}
