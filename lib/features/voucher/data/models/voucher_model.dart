class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    this.discountTypeLabel,
    this.discountValue = 0,
    this.maxDiscountAmount,
    this.minOrderAmount = 0,
    this.usageLimit,
    this.usedCount = 0,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String discountType;
  final String? discountTypeLabel;
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int? usageLimit;
  final int usedCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: _readString(json['id']),
      code: _readString(json['code']),
      name: _readString(json['name']),
      description: _readNullableString(json['description']),
      discountType: _readString(json['discountType']),
      discountTypeLabel: _readNullableString(json['discountTypeLabel']),
      discountValue: _readDouble(json['discountValue']),
      maxDiscountAmount: _readNullableDouble(json['maxDiscountAmount']),
      minOrderAmount: _readDouble(json['minOrderAmount']),
      usageLimit: _readNullableInt(json['usageLimit']),
      usedCount: _readInt(json['usedCount']),
      startDate: _readDateTime(json['startDate']),
      endDate: _readDateTime(json['endDate']),
      isActive: _readBool(json['isActive'], fallback: true),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'discountType': discountType,
      'discountTypeLabel': discountTypeLabel,
      'discountValue': discountValue,
      'maxDiscountAmount': maxDiscountAmount,
      'minOrderAmount': minOrderAmount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
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
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return text;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }

    return _readInt(value);
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
