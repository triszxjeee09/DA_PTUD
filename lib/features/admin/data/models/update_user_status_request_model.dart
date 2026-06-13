class UpdateUserStatusRequestModel {
  const UpdateUserStatusRequestModel({required this.status});

  final String status;

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}
