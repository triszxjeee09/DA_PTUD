class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.orderId,
    this.orderCode,
    required this.paymentMethod,
    this.amount = 0,
    this.transactionCode,
    required this.paymentStatus,
    this.paymentStatusLabel,
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String? orderCode;
  final String paymentMethod;
  final double amount;
  final String? transactionCode;
  final String paymentStatus;
  final String? paymentStatusLabel;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _readString(json['id']),
      orderId: _readString(json['orderId']),
      orderCode: _readNullableString(json['orderCode']),
      paymentMethod: _readString(json['paymentMethod']),
      amount: _readDouble(json['amount']),
      transactionCode: _readNullableString(json['transactionCode']),
      paymentStatus: _readString(json['paymentStatus']),
      paymentStatusLabel: _readNullableString(json['paymentStatusLabel']),
      paidAt: _readDateTime(json['paidAt']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'orderCode': orderCode,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'transactionCode': transactionCode,
      'paymentStatus': paymentStatus,
      'paymentStatusLabel': paymentStatusLabel,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
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
}
