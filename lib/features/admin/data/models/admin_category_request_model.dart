class AdminCategoryRequestModel {
  const AdminCategoryRequestModel({
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    required this.isActive,
  });

  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'imageUrl': imageUrl,
      'parentId': parentId,
      'isActive': isActive,
    };
  }
}
