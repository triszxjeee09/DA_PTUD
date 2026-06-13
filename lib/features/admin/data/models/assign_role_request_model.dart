class AssignRoleRequestModel {
  const AssignRoleRequestModel({required this.roleName});

  final String roleName;

  Map<String, dynamic> toJson() {
    return {'roleName': roleName};
  }
}
