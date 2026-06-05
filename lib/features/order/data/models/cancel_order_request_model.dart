class CancelOrderRequestModel {
  const CancelOrderRequestModel({required this.reason});

  final String reason;

  Map<String, dynamic> toJson() {
    return {'reason': reason};
  }
}
