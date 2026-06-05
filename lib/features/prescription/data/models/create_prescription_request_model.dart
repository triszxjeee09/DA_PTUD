class CreatePrescriptionRequestModel {
  const CreatePrescriptionRequestModel({
    required this.patientName,
    this.patientPhone,
    this.note,
    required this.imageUrls,
  });

  final String patientName;
  final String? patientPhone;
  final String? note;
  final List<String> imageUrls;

  Map<String, dynamic> toJson() {
    return {
      'patientName': patientName,
      'patientPhone': patientPhone,
      'note': note,
      'imageUrls': imageUrls,
    };
  }
}
