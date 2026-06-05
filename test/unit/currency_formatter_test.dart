import 'package:flutter_test/flutter_test.dart';
import 'package:doan/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format - Nhóm test PASS', () {
    test('PASS: Format 0 thành 0đ', () {
      final result = CurrencyFormatter.format(0);

      print('Kết quả thực tế: $result');
      expect(result, '0đ');
    });

    test('PASS: Format 35000 thành 35.000đ', () {
      final result = CurrencyFormatter.format(35000);

      print('Kết quả thực tế: $result');
      expect(result, '35.000đ');
    });

    test('PASS: Format 1200000 thành 1.200.000đ', () {
      final result = CurrencyFormatter.format(1200000);

      print('Kết quả thực tế: $result');
      expect(result, '1.200.000đ');
    });

    test('PASS: Format số âm -50000 thành -50.000đ', () {
      final result = CurrencyFormatter.format(-50000);

      print('Kết quả thực tế: $result');
      expect(result, '-50.000đ');
    });
  });

  group('CurrencyFormatter.format - Nhóm test FAIL cố tình', () {
    test('FAIL: 35000 nhưng mong muốn sai là 35000đ', () {
      final result = CurrencyFormatter.format(35000);

      print('Kết quả thực tế: $result');
      expect(result, '35000đ');
    });

    test('FAIL: 1200000 nhưng mong muốn sai là 1200000đ', () {
      final result = CurrencyFormatter.format(1200000);

      print('Kết quả thực tế: $result');
      expect(result, '1200000đ');
    });
  });
}