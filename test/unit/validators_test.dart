import 'package:flutter_test/flutter_test.dart';
import 'package:doan/core/utils/validators.dart';

void main() {
  group('Validators.requiredField - Test đúng', () {
    test('Trả lỗi khi value là null', () {
      final result = Validators.requiredField(null);

      expect(result, 'Trường này không được để trống');
    });

    test('Trả lỗi khi value là chuỗi rỗng', () {
      final result = Validators.requiredField('');

      expect(result, 'Trường này không được để trống');
    });

    test('Trả lỗi khi value chỉ có khoảng trắng', () {
      final result = Validators.requiredField('   ');

      expect(result, 'Trường này không được để trống');
    });

    test('Trả lỗi theo fieldName truyền vào', () {
      final result = Validators.requiredField('', fieldName: 'Họ tên');

      expect(result, 'Họ tên không được để trống');
    });

    test('Trả null khi value hợp lệ', () {
      final result = Validators.requiredField('Nguyễn Văn A');

      expect(result, isNull);
    });
  });

  group('Validators.phoneNumber - Test đúng', () {
    test('Trả lỗi khi số điện thoại null', () {
      final result = Validators.phoneNumber(null);

      expect(result, 'Số điện thoại không được để trống');
    });

    test('Trả lỗi khi số điện thoại rỗng', () {
      final result = Validators.phoneNumber('');

      expect(result, 'Số điện thoại không được để trống');
    });

    test('Trả lỗi khi số điện thoại sai định dạng', () {
      final result = Validators.phoneNumber('12345');

      expect(result, 'Số điện thoại không hợp lệ');
    });

    test('Trả lỗi khi số điện thoại có chữ cái', () {
      final result = Validators.phoneNumber('abc1234567');

      expect(result, 'Số điện thoại không hợp lệ');
    });

    test('Trả lỗi khi số điện thoại 11 số bắt đầu bằng 0', () {
      final result = Validators.phoneNumber('01234567890');

      expect(result, 'Số điện thoại không hợp lệ');
    });

    test('Trả null khi số điện thoại bắt đầu bằng 0 và có đúng 10 số', () {
      final result = Validators.phoneNumber('0332180384');

      expect(result, isNull);
    });

    test('Trả null khi số điện thoại bắt đầu bằng +84 và có đúng 9 số phía sau', () {
      final result = Validators.phoneNumber('+84332180384');

      expect(result, isNull);
    });

    test('Trả null khi số điện thoại có khoảng trắng đầu cuối', () {
      final result = Validators.phoneNumber(' 0332180384 ');

      expect(result, isNull);
    });
  });

  group('Test cố tình sai để thấy FAIL', () {
    test('SAI: số điện thoại hợp lệ nhưng lại mong muốn trả lỗi', () {
      final result = Validators.phoneNumber('0332180384');

      expect(result, 'Số điện thoại không hợp lệ');
    });

    test('SAI: field hợp lệ nhưng lại mong muốn báo lỗi rỗng', () {
      final result = Validators.requiredField('Nguyễn Văn A');

      expect(result, 'Trường này không được để trống');
    });
  });
}