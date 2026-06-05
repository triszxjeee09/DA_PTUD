import 'product_image_model.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    required this.name,
    required this.slug,
    required this.sku,
    this.shortDescription,
    this.description,
    this.ingredients,
    this.usageInstructions,
    this.dosage,
    this.sideEffects,
    this.precautions,
    this.storageInstructions,
    required this.unit,
    this.price = 0,
    this.originalPrice,
    this.requiresPrescription = false,
    this.isActive = true,
    this.isFeatured = false,
    this.thumbnailUrl,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? categoryId;
  final String? categoryName;
  final String? brandId;
  final String? brandName;
  final String name;
  final String slug;
  final String sku;
  final String? shortDescription;
  final String? description;
  final String? ingredients;
  final String? usageInstructions;
  final String? dosage;
  final String? sideEffects;
  final String? precautions;
  final String? storageInstructions;
  final String unit;
  final double price;
  final double? originalPrice;
  final bool requiresPrescription;
  final bool isActive;
  final bool isFeatured;
  final String? thumbnailUrl;
  final List<ProductImageModel> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _readString(json['id']),
      categoryId: _readNullableString(json['categoryId']),
      categoryName: _readNullableString(json['categoryName']),
      brandId: _readNullableString(json['brandId']),
      brandName: _readNullableString(json['brandName']),
      name: _readString(json['name']),
      slug: _readString(json['slug']),
      sku: _readString(json['sku']),
      shortDescription: _readNullableString(json['shortDescription']),
      description: _readNullableString(json['description']),
      ingredients: _readNullableString(json['ingredients']),
      usageInstructions: _readNullableString(json['usageInstructions']),
      dosage: _readNullableString(json['dosage']),
      sideEffects: _readNullableString(json['sideEffects']),
      precautions: _readNullableString(json['precautions']),
      storageInstructions: _readNullableString(json['storageInstructions']),
      unit: _readString(json['unit']),
      price: _readDouble(json['price']),
      originalPrice: _readNullableDouble(json['originalPrice']),
      requiresPrescription: _readBool(json['requiresPrescription']),
      isActive: _readBool(json['isActive'], fallback: true),
      isFeatured: _readBool(json['isFeatured']),
      thumbnailUrl: _readNullableString(json['thumbnailUrl']),
      images: _readImages(json['images']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brandId': brandId,
      'brandName': brandName,
      'name': name,
      'slug': slug,
      'sku': sku,
      'shortDescription': shortDescription,
      'description': description,
      'ingredients': ingredients,
      'usageInstructions': usageInstructions,
      'dosage': dosage,
      'sideEffects': sideEffects,
      'precautions': precautions,
      'storageInstructions': storageInstructions,
      'unit': unit,
      'price': price,
      'originalPrice': originalPrice,
      'requiresPrescription': requiresPrescription,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'thumbnailUrl': thumbnailUrl,
      'images': images.map((image) => image.toJson()).toList(),
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

  static double _readDouble(Object? value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static double? _readNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }

    return _readDouble(value);
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static List<ProductImageModel> _readImages(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(ProductImageModel.fromJson)
        .toList();
  }
}
