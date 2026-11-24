import 'package:an_tam_pharma/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PHAN 1 - PASS: Kiem thu dung Validators', () {
    group('requiredField', () {
      test('Tra loi khi value la null', () {
        final result = Validators.requiredField(null);

        expect(result, 'Trường này không được để trống');
      });

      test('Tra loi khi value la chuoi rong', () {
        final result = Validators.requiredField('');

        expect(result, 'Trường này không được để trống');
      });

      test('Tra loi khi value chi co khoang trang', () {
        final result = Validators.requiredField('   ');

        expect(result, 'Trường này không được để trống');
      });

      test('Tra loi theo fieldName truyen vao', () {
        final result = Validators.requiredField('', fieldName: 'Họ tên');

        expect(result, 'Họ tên không được để trống');
      });

      test('Tra null khi value hop le', () {
        final result = Validators.requiredField('Nguyễn Văn A');

        expect(result, isNull);
      });
    });

    group('phoneNumber', () {
      test('Tra loi khi so dien thoai null', () {
        final result = Validators.phoneNumber(null);

        expect(result, 'Số điện thoại không được để trống');
      });

      test('Tra loi khi so dien thoai rong', () {
        final result = Validators.phoneNumber('');

        expect(result, 'Số điện thoại không được để trống');
      });

      test('Tra loi khi so dien thoai sai dinh dang', () {
        final result = Validators.phoneNumber('12345');

        expect(result, 'Số điện thoại không hợp lệ');
      });

      test('Tra loi khi so dien thoai co chu cai', () {
        final result = Validators.phoneNumber('abc1234567');

        expect(result, 'Số điện thoại không hợp lệ');
      });

      test('Tra loi khi so dien thoai 11 so bat dau bang 0', () {
        final result = Validators.phoneNumber('01234567890');

        expect(result, 'Số điện thoại không hợp lệ');
      });

      test('Tra null khi so dien thoai bat dau bang 0 va co dung 10 so', () {
        final result = Validators.phoneNumber('0332180384');

        expect(result, isNull);
      });

      test(
        'Tra null khi so dien thoai bat dau bang +84 va co dung 9 so sau',
        () {
          final result = Validators.phoneNumber('+84332180384');

          expect(result, isNull);
        },
      );

      test('Tra null khi so dien thoai co khoang trang dau cuoi', () {
        final result = Validators.phoneNumber(' 0332180384 ');

        expect(result, isNull);
      });
    });
  });

  group('PHAN 2 - Kiem thu Validators bo sung', () {
    test('so dien thoai hop le tra null', () {
      final result = Validators.phoneNumber('0332180384');

      expect(result, isNull);
    });

    test('field hop le tra null', () {
      final result = Validators.requiredField('Nguyễn Văn A');

      expect(result, isNull);
    });
  });
}
