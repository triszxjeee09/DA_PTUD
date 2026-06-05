class AddToCartRequestModel {
  const AddToCartRequestModel({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'quantity': quantity};
  }
}
