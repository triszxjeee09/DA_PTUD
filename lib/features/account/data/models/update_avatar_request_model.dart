class UpdateAvatarRequestModel {
  const UpdateAvatarRequestModel({required this.avatarUrl});

  final String avatarUrl;

  Map<String, dynamic> toJson() {
    return {'avatarUrl': avatarUrl};
  }
}
