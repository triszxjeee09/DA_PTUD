class SaveDeviceTokenRequestModel {
  const SaveDeviceTokenRequestModel({
    required this.token,
    required this.platform,
  });

  final String token;
  final String platform;

  Map<String, dynamic> toJson() {
    return {'token': token, 'platform': platform};
  }
}
