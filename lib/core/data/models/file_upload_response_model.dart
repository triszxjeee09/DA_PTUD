class FileUploadResponseModel {
  const FileUploadResponseModel({
    required this.fileName,
    required this.originalFileName,
    required this.fileUrl,
    required this.contentType,
    required this.size,
  });

  final String fileName;
  final String originalFileName;
  final String fileUrl;
  final String contentType;
  final int size;

  factory FileUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return FileUploadResponseModel(
      fileName: _readString(json['fileName']),
      originalFileName: _readString(json['originalFileName']),
      fileUrl: _readString(json['fileUrl']),
      contentType: _readString(json['contentType']),
      size: _readInt(json['size']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'originalFileName': originalFileName,
      'fileUrl': fileUrl,
      'contentType': contentType,
      'size': size,
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }
}
