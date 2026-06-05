class AdminVoucherRequestModel {
  const AdminVoucherRequestModel({
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.minOrderAmount,
    this.usageLimit,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  final String code;
  final String name;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int? usageLimit;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'maxDiscountAmount': maxDiscountAmount,
      'minOrderAmount': minOrderAmount,
      'usageLimit': usageLimit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
