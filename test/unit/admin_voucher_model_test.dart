import 'package:doan/features/admin/data/models/admin_voucher_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminVoucherModel', () {
    test('parse được voucherId từ backend admin', () {
      final voucher = AdminVoucherModel.fromJson(const {
        'voucherId': 'voucher-1',
        'code': 'SALE10',
        'name': 'Sale 10%',
        'discountType': 'PERCENT',
      });

      expect(voucher.id, 'voucher-1');
      expect(voucher.code, 'SALE10');
      expect(voucher.name, 'Sale 10%');
    });

    test('parse được voucher_id dạng snake_case', () {
      final voucher = AdminVoucherModel.fromJson(const {
        'voucher_id': 10,
        'code': 'SHIPFREE',
        'name': 'Miễn phí vận chuyển',
        'discountType': 'FIXED',
      });

      expect(voucher.id, '10');
    });
  });
}
