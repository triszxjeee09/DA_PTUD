import 'cart_item_model.dart';

class CartModel {
  const CartModel({
    required this.id,
    required this.status,
    this.items = const [],
    this.totalItems = 0,
    this.totalAmount = 0,
    this.hasPrescriptionProduct = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String status;
  final List<CartItemModel> items;
  final int totalItems;
  final double totalAmount;
  final bool hasPrescriptionProduct;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: _readString(json['id']),
      status: _readString(json['status']),
      items: _readItems(json['items']),
      totalItems: _readInt(json['totalItems']),
      totalAmount: _readDouble(json['totalAmount']),
      hasPrescriptionProduct: _readBool(json['hasPrescriptionProduct']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'totalItems': totalItems,
      'totalAmount': totalAmount,
      'hasPrescriptionProduct': hasPrescriptionProduct,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
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

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static List<CartItemModel> _readItems(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(CartItemModel.fromJson)
        .toList();
  }
}
