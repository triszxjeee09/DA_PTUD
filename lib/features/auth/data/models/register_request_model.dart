class RegisterRequestModel {
  const RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }
}
