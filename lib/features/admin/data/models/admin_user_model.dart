class AdminUserModel {
  const AdminUserModel({
    required this.id,
    this.username,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.authProvider,
    this.status = 'ACTIVE',
    this.roles = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? username;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? gender;
  final String? dateOfBirth;
  final String? authProvider;
  final String status;
  final List<String> roles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: _readString(
        json['id'] ??
            json['userId'] ??
            json['user_id'] ??
            json['accountId'] ??
            json['account_id'],
      ),
      username: _readNullableString(json['username']),
      fullName: _readNullableString(json['fullName']),
      email: _readNullableString(json['email']),
      phone: _readNullableString(json['phone']),
      avatarUrl: _readNullableString(json['avatarUrl'] ?? json['avatar']),
      gender: _readNullableString(json['gender']),
      dateOfBirth: _readNullableString(json['dateOfBirth']),
      authProvider: _readNullableString(json['authProvider']),
      status: _readString(json['status'], fallback: 'ACTIVE'),
      roles: _readStringList(json['roles']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'authProvider': authProvider,
      'status': status,
      'roles': roles,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static List<String> _readStringList(Object? value) {
    if (value is String) {
      final role = value.trim();
      return role.isEmpty ? const [] : [role];
    }

    if (value is! List) {
      return const [];
    }

    return value
        .map(_readRole)
        .where((role) => role != null && role.isNotEmpty)
        .cast<String>()
        .toList();
  }

  static String? _readRole(Object? value) {
    if (value is Map) {
      final role =
          value['role'] ?? value['name'] ?? value['authority'] ?? value['code'];
      return _readNullableString(role);
    }

    return _readNullableString(value);
  }
}
