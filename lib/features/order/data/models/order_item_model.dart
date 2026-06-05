class OrderItemModel {
  const OrderItemModel({
    required this.id,
    this.productId,
    required this.productName,
    this.productImage,
    this.unitPrice = 0,
    this.quantity = 0,
    this.totalPrice = 0,
  });

  final String id;
  final String? productId;
  final String productName;
  final String? productImage;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: _readString(json['id']),
      productId: _readNullableString(json['productId']),
      productName: _readString(json['productName']),
      productImage: _readNullableString(json['productImage']),
      unitPrice: _readDouble(json['unitPrice']),
      quantity: _readInt(json['quantity']),
      totalPrice: _readDouble(json['totalPrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
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
}
