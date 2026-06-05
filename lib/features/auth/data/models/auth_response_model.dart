import 'user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final UserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userJson = rawUser is Map
        ? rawUser.map((key, value) => MapEntry(key.toString(), value))
        : json;

    return AuthResponseModel(
      accessToken: json['accessToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: UserModel.fromJson(userJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'user': user.toJson(),
    };
  }
}
