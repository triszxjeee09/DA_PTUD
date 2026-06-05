class ApplyVoucherRequestModel {
  const ApplyVoucherRequestModel({
    required this.code,
    required this.orderAmount,
  });

  final String code;
  final double orderAmount;

  Map<String, dynamic> toJson() {
    return {'code': code, 'orderAmount': orderAmount};
  }
}
