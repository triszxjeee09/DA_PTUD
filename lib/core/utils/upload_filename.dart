/// Xác định tên file hợp lệ để gửi lên máy chủ (thuần Dart, dễ kiểm thử).
class UploadFilename {
  const UploadFilename._();

  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
  };

  /// Tên file gửi lên: giữ tên gốc nếu đã có đuôi hợp lệ, ngược lại suy ra đuôi
  /// từ MIME hoặc nội dung file (trình duyệt đôi khi trả tên không có đuôi).
  static String resolve(String name, String? mimeType, List<int> bytes) {
    final cleaned = name.trim().isEmpty ? 'upload' : name.trim();
    final dot = cleaned.lastIndexOf('.');
    final currentExt = dot >= 0 ? cleaned.substring(dot + 1).toLowerCase() : '';
    if (allowedExtensions.contains(currentExt)) {
      return cleaned;
    }

    final ext = _extFromMime(mimeType) ?? _extFromBytes(bytes) ?? 'jpg';
    final base = dot > 0 ? cleaned.substring(0, dot) : cleaned;
    return '$base.$ext';
  }

  static String? _extFromMime(String? mimeType) {
    switch (mimeType?.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'application/pdf':
        return 'pdf';
    }
    return null;
  }

  static String? _extFromBytes(List<int> b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'jpg';
    }
    if (b.length >= 4 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) {
      return 'png';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return 'webp';
    }
    if (b.length >= 4 &&
        b[0] == 0x25 &&
        b[1] == 0x50 &&
        b[2] == 0x44 &&
        b[3] == 0x46) {
      return 'pdf';
    }
    return null;
  }
}
