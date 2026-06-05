class VnPayReturnResponseModel {
  const VnPayReturnResponseModel({
    this.responseCode,
    this.transactionStatus,
    this.transactionNo,
    this.bankCode,
    this.orderInfo,
    this.orderCode,
    this.amount = 0,
    this.message,
    this.success = false,
  });

  final String? responseCode;
  final String? transactionStatus;
  final String? transactionNo;
  final String? bankCode;
  final String? orderInfo;
  final String? orderCode;
  final double amount;
  final String? message;
  final bool success;

  factory VnPayReturnResponseModel.fromJson(Map<String, dynamic> json) {
    return VnPayReturnResponseModel(
      responseCode: _readNullableString(json['responseCode']),
      transactionStatus: _readNullableString(json['transactionStatus']),
      transactionNo: _readNullableString(json['transactionNo']),
      bankCode: _readNullableString(json['bankCode']),
      orderInfo: _readNullableString(json['orderInfo']),
      orderCode: _readNullableString(json['orderCode']),
      amount: _readDouble(json['amount']),
      message: _readNullableString(json['message']),
      success: _readBool(json['success']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responseCode': responseCode,
      'transactionStatus': transactionStatus,
      'transactionNo': transactionNo,
      'bankCode': bankCode,
      'orderInfo': orderInfo,
      'orderCode': orderCode,
      'amount': amount,
      'message': message,
      'success': success,
    };
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

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
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
