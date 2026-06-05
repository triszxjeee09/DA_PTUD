class ResetPasswordWithOtpRequestModel {
  const ResetPasswordWithOtpRequestModel({
    required this.username,
    required this.otpCode,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String username;
  final String otpCode;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'otpCode': otpCode,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}
