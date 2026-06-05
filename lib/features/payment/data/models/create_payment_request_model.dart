class CreatePaymentRequestModel {
  const CreatePaymentRequestModel({
    required this.orderId,
    required this.paymentMethod,
  });

  final String orderId;
  final String paymentMethod;

  Map<String, dynamic> toJson() {
    return {'orderId': orderId, 'paymentMethod': paymentMethod};
  }
}
