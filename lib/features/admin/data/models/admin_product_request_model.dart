class AdminProductRequestModel {
  const AdminProductRequestModel({
    required this.name,
    required this.sku,
    required this.slug,
    required this.categoryId,
    this.brandId,
    this.shortDescription,
    this.description,
    this.ingredients,
    this.usageInstructions,
    this.dosage,
    this.sideEffects,
    this.precautions,
    this.storageInstructions,
    this.dosageForm,
    this.targetAudience,
    this.symptoms,
    this.manufacturer,
    this.contraindications,
    required this.unit,
    required this.price,
    this.originalPrice,
    required this.requiresPrescription,
    required this.isFeatured,
    required this.isActive,
  });

  final String name;
  final String sku;
  final String slug;
  final String categoryId;
  final String? brandId;
  final String? shortDescription;
  final String? description;
  final String? ingredients;
  final String? usageInstructions;
  final String? dosage;
  final String? sideEffects;
  final String? precautions;
  final String? storageInstructions;
  final String? dosageForm;
  final String? targetAudience;
  final String? symptoms;
  final String? manufacturer;
  final String? contraindications;
  final String unit;
  final double price;
  final double? originalPrice;
  final bool requiresPrescription;
  final bool isFeatured;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'slug': slug,
      'categoryId': categoryId,
      'brandId': brandId,
      'shortDescription': shortDescription,
      'description': description,
      'ingredients': ingredients,
      'usageInstructions': usageInstructions,
      'dosage': dosage,
      'sideEffects': sideEffects,
      'precautions': precautions,
      'storageInstructions': storageInstructions,
      'dosageForm': dosageForm,
      'targetAudience': targetAudience,
      'symptoms': symptoms,
      'manufacturer': manufacturer,
      'contraindications': contraindications,
      'unit': unit,
      'price': price,
      'originalPrice': originalPrice,
      'requiresPrescription': requiresPrescription,
      'isFeatured': isFeatured,
      'isActive': isActive,
    };
  }
}
