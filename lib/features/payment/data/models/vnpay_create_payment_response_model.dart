class VnPayCreatePaymentResponseModel {
  const VnPayCreatePaymentResponseModel({
    required this.paymentUrl,
    required this.orderId,
    required this.orderCode,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  final String paymentUrl;
  final String orderId;
  final String orderCode;
  final double amount;
  final String paymentMethod;
  final String paymentStatus;

  factory VnPayCreatePaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return VnPayCreatePaymentResponseModel(
      paymentUrl: _readString(json['paymentUrl']),
      orderId: _readString(json['orderId']),
      orderCode: _readString(json['orderCode']),
      amount: _readDouble(json['amount']),
      paymentMethod: _readString(json['paymentMethod']),
      paymentStatus: _readString(json['paymentStatus']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentUrl': paymentUrl,
      'orderId': orderId,
      'orderCode': orderCode,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
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
