class AdminActivityLogModel {
  const AdminActivityLogModel({
    required this.id,
    this.userId,
    this.userFullName,
    this.userEmail,
    required this.action,
    this.actionLabel,
    this.entityName,
    this.entityId,
    this.description,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String? userFullName;
  final String? userEmail;
  final String action;
  final String? actionLabel;
  final String? entityName;
  final String? entityId;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  factory AdminActivityLogModel.fromJson(Map<String, dynamic> json) {
    return AdminActivityLogModel(
      id: _readString(json['id']),
      userId: _readNullableString(json['userId']),
      userFullName: _readNullableString(json['userFullName']),
      userEmail: _readNullableString(json['userEmail']),
      action: _readString(json['action']),
      actionLabel: _readNullableString(json['actionLabel']),
      entityName: _readNullableString(json['entityName']),
      entityId: _readNullableString(json['entityId']),
      description: _readNullableString(json['description']),
      ipAddress: _readNullableString(json['ipAddress']),
      userAgent: _readNullableString(json['userAgent']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
