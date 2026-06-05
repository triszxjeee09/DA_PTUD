class CreateProductReviewRequestModel {
  const CreateProductReviewRequestModel({
    required this.productId,
    this.orderId,
    required this.rating,
    this.comment,
  });

  final String productId;
  final String? orderId;
  final int rating;
  final String? comment;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    };
  }
}
