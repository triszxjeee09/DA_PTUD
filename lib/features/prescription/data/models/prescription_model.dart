import 'prescription_image_model.dart';

class PrescriptionModel {
  const PrescriptionModel({
    required this.id,
    this.userId,
    this.customerName,
    this.pharmacistId,
    this.pharmacistName,
    required this.patientName,
    this.patientPhone,
    this.note,
    required this.status,
    required this.statusLabel,
    this.pharmacistNote,
    this.reviewedAt,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String? customerName;
  final String? pharmacistId;
  final String? pharmacistName;
  final String patientName;
  final String? patientPhone;
  final String? note;
  final String status;
  final String statusLabel;
  final String? pharmacistNote;
  final DateTime? reviewedAt;
  final List<PrescriptionImageModel> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: _readString(json['id']),
      userId: _readNullableString(json['userId']),
      customerName: _readNullableString(json['customerName']),
      pharmacistId: _readNullableString(json['pharmacistId']),
      pharmacistName: _readNullableString(json['pharmacistName']),
      patientName: _readString(json['patientName']),
      patientPhone: _readNullableString(json['patientPhone']),
      note: _readNullableString(json['note']),
      status: _readString(json['status']),
      statusLabel: _readString(json['statusLabel']),
      pharmacistNote: _readNullableString(json['pharmacistNote']),
      reviewedAt: _readDateTime(json['reviewedAt']),
      images: _readImages(json['images']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'pharmacistId': pharmacistId,
      'pharmacistName': pharmacistName,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'note': note,
      'status': status,
      'statusLabel': statusLabel,
      'pharmacistNote': pharmacistNote,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'images': images.map((image) => image.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static List<PrescriptionImageModel> _readImages(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (image) => image.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(PrescriptionImageModel.fromJson)
        .toList();
  }
}
