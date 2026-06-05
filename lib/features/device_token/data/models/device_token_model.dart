class DeviceTokenModel {
  const DeviceTokenModel({
    required this.id,
    required this.token,
    required this.platform,
    this.active = false,
    this.lastUsedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String token;
  final String platform;
  final bool active;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: _readString(json['id']),
      token: _readString(json['token']),
      platform: _readString(json['platform']),
      active: _readBool(json['active']),
      lastUsedAt: _readDateTime(json['lastUsedAt']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'platform': platform,
      'active': active,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    return fallback;
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
