class UpdatePaymentStatusRequestModel {
  const UpdatePaymentStatusRequestModel({
    required this.paymentStatus,
    this.transactionCode,
  });

  final String paymentStatus;
  final String? transactionCode;

  Map<String, dynamic> toJson() {
    return {'paymentStatus': paymentStatus, 'transactionCode': transactionCode};
  }
}
