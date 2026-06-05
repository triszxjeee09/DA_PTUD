class ProductImageModel {
  const ProductImageModel({
    required this.id,
    required this.imageUrl,
    this.isThumbnail = false,
    this.sortOrder = 0,
  });

  final String id;
  final String imageUrl;
  final bool isThumbnail;
  final int sortOrder;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: _readString(json['id']),
      imageUrl: _readString(json['imageUrl']),
      isThumbnail: _readBool(json['isThumbnail']),
      sortOrder: _readInt(json['sortOrder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'isThumbnail': isThumbnail,
      'sortOrder': sortOrder,
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    return fallback;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}
