class VerifyForgotPasswordOtpResponseModel {
  const VerifyForgotPasswordOtpResponseModel({
    required this.verified,
    required this.message,
  });

  final bool verified;
  final String message;

  factory VerifyForgotPasswordOtpResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerifyForgotPasswordOtpResponseModel(
      verified: _readBool(json['verified']),
      message: _readString(json['message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'verified': verified, 'message': message};
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
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

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }
}
