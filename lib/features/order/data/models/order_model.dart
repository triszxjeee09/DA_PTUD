import 'order_item_model.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderCode,
    this.userId,
    this.customerName,
    this.addressId,
    this.receiverName,
    this.receiverPhone,
    this.shippingAddress,
    this.pharmacyId,
    this.pharmacyName,
    this.prescriptionId,
    this.voucherId,
    this.voucherCode,
    this.totalAmount = 0,
    this.discountAmount = 0,
    this.shippingFee = 0,
    this.finalAmount = 0,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.orderStatusLabel,
    this.note,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderCode;
  final String? userId;
  final String? customerName;
  final String? addressId;
  final String? receiverName;
  final String? receiverPhone;
  final String? shippingAddress;
  final String? pharmacyId;
  final String? pharmacyName;
  final String? prescriptionId;
  final String? voucherId;
  final String? voucherCode;
  final double totalAmount;
  final double discountAmount;
  final double shippingFee;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String orderStatusLabel;
  final String? note;
  final List<OrderItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: _readString(json['id']),
      orderCode: _readString(json['orderCode']),
      userId: _readNullableString(json['userId']),
      customerName: _readNullableString(json['customerName']),
      addressId: _readNullableString(json['addressId']),
      receiverName: _readNullableString(json['receiverName']),
      receiverPhone: _readNullableString(json['receiverPhone']),
      shippingAddress: _readNullableString(json['shippingAddress']),
      pharmacyId: _readNullableString(json['pharmacyId']),
      pharmacyName: _readNullableString(json['pharmacyName']),
      prescriptionId: _readNullableString(json['prescriptionId']),
      voucherId: _readNullableString(json['voucherId']),
      voucherCode: _readNullableString(json['voucherCode']),
      totalAmount: _readDouble(json['totalAmount']),
      discountAmount: _readDouble(json['discountAmount']),
      shippingFee: _readDouble(json['shippingFee']),
      finalAmount: _readDouble(json['finalAmount']),
      paymentMethod: _readString(json['paymentMethod']),
      paymentStatus: _readString(json['paymentStatus']),
      orderStatus: _readString(json['orderStatus']),
      orderStatusLabel: _readString(json['orderStatusLabel']),
      note: _readNullableString(json['note']),
      items: _readItems(json['items']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderCode': orderCode,
      'userId': userId,
      'customerName': customerName,
      'addressId': addressId,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'shippingAddress': shippingAddress,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'prescriptionId': prescriptionId,
      'voucherId': voucherId,
      'voucherCode': voucherCode,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'shippingFee': shippingFee,
      'finalAmount': finalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'orderStatusLabel': orderStatusLabel,
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
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

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static List<OrderItemModel> _readItems(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(OrderItemModel.fromJson)
        .toList();
  }
}
