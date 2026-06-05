class VerifyForgotPasswordOtpRequestModel {
  const VerifyForgotPasswordOtpRequestModel({
    required this.username,
    required this.otpCode,
  });

  final String username;
  final String otpCode;

  Map<String, dynamic> toJson() {
    return {'username': username, 'otpCode': otpCode};
  }
}
