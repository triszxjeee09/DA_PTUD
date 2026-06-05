class AdminBrandRequestModel {
  const AdminBrandRequestModel({
    required this.name,
    this.country,
    this.description,
    this.logoUrl,
    required this.isActive,
  });

  final String name;
  final String? country;
  final String? description;
  final String? logoUrl;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'description': description,
      'logoUrl': logoUrl,
      'isActive': isActive,
    };
  }
}
