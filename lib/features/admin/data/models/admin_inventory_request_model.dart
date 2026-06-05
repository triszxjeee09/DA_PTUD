class AdminInventoryRequestModel {
  const AdminInventoryRequestModel({
    required this.pharmacyId,
    required this.productId,
    required this.quantity,
  });

  final String pharmacyId;
  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {
      'pharmacyId': pharmacyId,
      'productId': productId,
      'quantity': quantity,
    };
  }
}
