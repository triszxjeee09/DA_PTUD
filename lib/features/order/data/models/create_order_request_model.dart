class CreateOrderRequestModel {
  const CreateOrderRequestModel({
    required this.addressId,
    this.pharmacyId,
    this.prescriptionId,
    this.voucherId,
    required this.paymentMethod,
    this.note,
  });

  final String addressId;
  final String? pharmacyId;
  final String? prescriptionId;
  final String? voucherId;
  final String paymentMethod;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      'pharmacyId': pharmacyId,
      'prescriptionId': prescriptionId,
      'voucherId': voucherId,
      'paymentMethod': paymentMethod,
      'note': note,
    };
  }
}
