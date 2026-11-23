import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'upload_filename.dart';

/// Chuẩn bị file người dùng chọn để gửi multipart.
///
/// Dùng `XFile` + bytes thay cho `dart:io File` để chạy được cả trên Flutter Web
/// (trên web không có đường dẫn file thật, chỉ có blob).
class UploadFile {
  const UploadFile._();

  static Future<MultipartFile> toMultipart(XFile file) async {
    final bytes = await file.readAsBytes();
    return MultipartFile.fromBytes(
      bytes,
      filename: UploadFilename.resolve(file.name, file.mimeType, bytes),
    );
  }
}
