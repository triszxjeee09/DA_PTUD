import 'order_item_model.dart';
import 'order_model.dart';
import 'order_status_history_model.dart';

class OrderDetailModel extends OrderModel {
  const OrderDetailModel({
    required super.id,
    required super.orderCode,
    super.userId,
    super.customerName,
    super.addressId,
    super.receiverName,
    super.receiverPhone,
    super.shippingAddress,
    super.pharmacyId,
    super.pharmacyName,
    super.prescriptionId,
    super.voucherId,
    super.voucherCode,
    super.totalAmount,
    super.discountAmount,
    super.shippingFee,
    super.finalAmount,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.orderStatus,
    required super.orderStatusLabel,
    super.note,
    super.items,
    super.createdAt,
    super.updatedAt,
    this.statusHistories = const [],
  });

  final List<OrderStatusHistoryModel> statusHistories;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
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
      statusHistories: _readStatusHistories(json['statusHistories']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'statusHistories': statusHistories
          .map((history) => history.toJson())
          .toList(),
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

  static List<OrderStatusHistoryModel> _readStatusHistories(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(OrderStatusHistoryModel.fromJson)
        .toList();
  }
}
