class ProductReviewModel {
  const ProductReviewModel({
    required this.id,
    this.userId,
    this.userFullName,
    this.userAvatarUrl,
    this.productId,
    this.productName,
    this.orderId,
    this.rating = 0,
    this.comment,
    this.isVisible = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String? userFullName;
  final String? userAvatarUrl;
  final String? productId;
  final String? productName;
  final String? orderId;
  final int rating;
  final String? comment;
  final bool isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      id: _readString(json['id']),
      userId: _readNullableString(json['userId']),
      userFullName: _readNullableString(json['userFullName']),
      userAvatarUrl: _readNullableString(json['userAvatarUrl']),
      productId: _readNullableString(json['productId']),
      productName: _readNullableString(json['productName']),
      orderId: _readNullableString(json['orderId']),
      rating: _readInt(json['rating']),
      comment: _readNullableString(json['comment']),
      isVisible: _readBool(json['isVisible'], fallback: true),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'userAvatarUrl': userAvatarUrl,
      'productId': productId,
      'productName': productName,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'isVisible': isVisible,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return text;
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

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
