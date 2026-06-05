class ForgotPasswordResponseModel {
  const ForgotPasswordResponseModel({
    required this.message,
    required this.expiresInMinutes,
  });

  final String message;
  final int expiresInMinutes;

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponseModel(
      message: _readString(json['message']),
      expiresInMinutes: _readInt(json['expiresInMinutes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'expiresInMinutes': expiresInMinutes};
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
}
