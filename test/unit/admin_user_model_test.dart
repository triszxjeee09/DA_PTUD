import 'package:doan/features/admin/data/models/admin_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminUserModel', () {
    test('parse được userId từ backend admin', () {
      final user = AdminUserModel.fromJson(const {
        'userId': 'admin-user-1',
        'fullName': 'Nguyễn Văn A',
        'email': 'user@example.com',
      });

      expect(user.id, 'admin-user-1');
      expect(user.fullName, 'Nguyễn Văn A');
      expect(user.email, 'user@example.com');
    });

    test('parse được user_id dạng snake_case', () {
      final user = AdminUserModel.fromJson(const {
        'user_id': 123,
        'username': 'customer123',
      });

      expect(user.id, '123');
      expect(user.username, 'customer123');
    });
  });
}
