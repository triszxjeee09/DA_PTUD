class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.description,
    this.isActive = true,
    this.parentId,
    this.parentName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? description;
  final bool isActive;
  final String? parentId;
  final String? parentName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _readString(json['id']),
      name: _readString(json['name']),
      slug: _readString(json['slug']),
      imageUrl: _readNullableString(json['imageUrl']),
      description: _readNullableString(json['description']),
      isActive: _readBool(json['isActive'], fallback: true),
      parentId: _readNullableString(json['parentId']),
      parentName: _readNullableString(json['parentName']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'parentId': parentId,
      'parentName': parentName,
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
