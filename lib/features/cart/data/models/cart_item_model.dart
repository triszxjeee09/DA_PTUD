class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.productImage,
    required this.unit,
    this.unitPrice = 0,
    this.quantity = 0,
    this.totalPrice = 0,
    this.requiresPrescription = false,
    this.isActive = true,
  });

  final String id;
  final String productId;
  final String productName;
  final String? productSlug;
  final String? productImage;
  final String unit;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final bool requiresPrescription;
  final bool isActive;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: _readString(json['id']),
      productId: _readString(json['productId']),
      productName: _readString(json['productName']),
      productSlug: _readNullableString(json['productSlug']),
      productImage: _readNullableString(json['productImage']),
      unit: _readString(json['unit']),
      unitPrice: _readDouble(json['unitPrice']),
      quantity: _readInt(json['quantity']),
      totalPrice: _readDouble(json['totalPrice']),
      requiresPrescription: _readBool(json['requiresPrescription']),
      isActive: _readBool(json['isActive'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productSlug': productSlug,
      'productImage': productImage,
      'unit': unit,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'requiresPrescription': requiresPrescription,
      'isActive': isActive,
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
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

  static double _readDouble(Object? value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
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
}
