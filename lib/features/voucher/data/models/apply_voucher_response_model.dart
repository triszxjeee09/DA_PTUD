class ApplyVoucherResponseModel {
  const ApplyVoucherResponseModel({
    required this.voucherId,
    required this.code,
    required this.name,
    this.orderAmount = 0,
    this.discountAmount = 0,
    this.finalAmount = 0,
    this.message,
  });

  final String voucherId;
  final String code;
  final String name;
  final double orderAmount;
  final double discountAmount;
  final double finalAmount;
  final String? message;

  factory ApplyVoucherResponseModel.fromJson(Map<String, dynamic> json) {
    return ApplyVoucherResponseModel(
      voucherId: _readString(json['voucherId']),
      code: _readString(json['code']),
      name: _readString(json['name']),
      orderAmount: _readDouble(json['orderAmount']),
      discountAmount: _readDouble(json['discountAmount']),
      finalAmount: _readDouble(json['finalAmount']),
      message: _readNullableString(json['message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucherId': voucherId,
      'code': code,
      'name': name,
      'orderAmount': orderAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'message': message,
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
}
