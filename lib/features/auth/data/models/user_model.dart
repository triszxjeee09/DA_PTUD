class UserModel {
  const UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.status,
    this.roles = const [],
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? status;
  final List<String> roles;
  final DateTime? createdAt;

  bool get isAdmin => _hasRole('ADMIN');

  bool get isPharmacist => _hasRole('PHARMACIST');

  bool get isCustomer => _hasRole('CUSTOMER');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _readString(json['id']),
      fullName: _readNullableString(json['fullName']),
      email: _readNullableString(json['email']),
      phone: _readNullableString(json['phone']),
      avatarUrl: _readNullableString(json['avatarUrl']),
      gender: _readNullableString(json['gender']),
      dateOfBirth: _readDateTime(json['dateOfBirth']),
      status: _readNullableString(json['status']),
      roles: _readStringList(json['roles']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'status': status,
      'roles': roles,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    String? status,
    List<String>? roles,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      status: status ?? this.status,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool _hasRole(String role) {
    return roles.any((value) {
      final normalizedRole = value.trim().toUpperCase();
      return normalizedRole == role || normalizedRole == 'ROLE_$role';
    });
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
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
      final role = value['role'] ?? value['name'] ?? value['authority'];
      return _readNullableString(role);
    }

    return _readNullableString(value);
  }
}
