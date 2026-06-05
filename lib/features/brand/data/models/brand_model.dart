class BrandModel {
  const BrandModel({
    required this.id,
    required this.name,
    this.country,
    this.description,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? country;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: _readString(json['id']),
      name: _readString(json['name']),
      country: _readNullableString(json['country']),
      description: _readNullableString(json['description']),
      logoUrl: _readNullableString(json['logoUrl']),
      isActive: _readBool(json['isActive'], fallback: true),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'description': description,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
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
    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
