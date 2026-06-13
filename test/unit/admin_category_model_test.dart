import 'package:doan/features/admin/data/models/admin_category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminCategoryModel', () {
    test('parse được categoryId từ backend admin', () {
      final category = AdminCategoryModel.fromJson(const {
        'categoryId': 'category-1',
        'name': 'Thuốc cảm cúm',
        'slug': 'thuoc-cam-cum',
      });

      expect(category.id, 'category-1');
      expect(category.name, 'Thuốc cảm cúm');
      expect(category.slug, 'thuoc-cam-cum');
    });

    test('parse được category_id dạng snake_case', () {
      final category = AdminCategoryModel.fromJson(const {
        'category_id': 12,
        'name': 'Vitamin',
        'slug': 'vitamin',
      });

      expect(category.id, '12');
    });
  });
}
