class UpdateCartItemRequestModel {
  const UpdateCartItemRequestModel({required this.quantity});

  final int quantity;

  Map<String, dynamic> toJson() {
    return {'quantity': quantity};
  }
}
