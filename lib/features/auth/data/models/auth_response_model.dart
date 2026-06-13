import 'user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final UserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userJson = rawUser is Map
        ? rawUser.map((key, value) => MapEntry(key.toString(), value))
        : json;

    return AuthResponseModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      user: UserModel.fromJson(userJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'user': user.toJson(),
    };
  }
}
