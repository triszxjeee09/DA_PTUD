import 'package:an_tam_pharma/core/utils/upload_filename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const png = [0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0, 0, 0, 0, 0];
  const jpg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0];
  const webp = [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50];

  group('UploadFilename.resolve', () {
    test('giữ nguyên tên có đuôi hợp lệ', () {
      expect(UploadFilename.resolve('don-thuoc.JPG', null, jpg), 'don-thuoc.JPG');
      expect(UploadFilename.resolve('scan.png', 'image/png', png), 'scan.png');
    });

    test('tên không có đuôi (Flutter Web) -> suy ra từ MIME', () {
      expect(UploadFilename.resolve('blob', 'image/png', const []), 'blob.png');
      expect(UploadFilename.resolve('image', 'image/jpeg', const []), 'image.jpg');
    });

    test('không có MIME -> suy ra từ nội dung file', () {
      expect(UploadFilename.resolve('abc', null, png), 'abc.png');
      expect(UploadFilename.resolve('abc', '', jpg), 'abc.jpg');
      expect(UploadFilename.resolve('abc', null, webp), 'abc.webp');
    });

    test('đuôi lạ được thay bằng đuôi đúng, tên rỗng có tên mặc định', () {
      expect(UploadFilename.resolve('photo.heic', 'image/jpeg', jpg), 'photo.jpg');
      expect(UploadFilename.resolve('', null, jpg), 'upload.jpg');
      expect(UploadFilename.resolve('x', null, const [1, 2, 3]), 'x.jpg');
    });
  });
}
