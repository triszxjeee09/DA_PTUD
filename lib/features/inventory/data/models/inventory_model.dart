class InventoryModel {
  const InventoryModel({
    required this.id,
    required this.pharmacyId,
    this.pharmacyName,
    this.pharmacyAddress,
    required this.productId,
    this.productName,
    this.productSku,
    this.productImage,
    this.quantity = 0,
    this.updatedAt,
  });

  final String id;
  final String pharmacyId;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String productId;
  final String? productName;
  final String? productSku;
  final String? productImage;
  final int quantity;
  final DateTime? updatedAt;

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: _readString(json['id']),
      pharmacyId: _readString(json['pharmacyId']),
      pharmacyName: _readNullableString(json['pharmacyName']),
      pharmacyAddress: _readNullableString(json['pharmacyAddress']),
      productId: _readString(json['productId']),
      productName: _readNullableString(json['productName']),
      productSku: _readNullableString(json['productSku']),
      productImage: _readNullableString(json['productImage']),
      quantity: _readInt(json['quantity']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'productImage': productImage,
      'quantity': quantity,
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
      return int.tryParse(value.trim()) ?? fallback;
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
