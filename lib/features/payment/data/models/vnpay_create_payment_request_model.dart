class VnPayCreatePaymentRequestModel {
  const VnPayCreatePaymentRequestModel({required this.orderId});

  final String orderId;

  Map<String, dynamic> toJson() {
    return {'orderId': orderId};
  }
}
