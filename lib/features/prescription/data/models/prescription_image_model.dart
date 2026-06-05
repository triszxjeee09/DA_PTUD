class PrescriptionImageModel {
  const PrescriptionImageModel({
    required this.id,
    required this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String imageUrl;
  final DateTime? createdAt;

  factory PrescriptionImageModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionImageModel(
      id: _readString(json['id']),
      imageUrl: _readString(json['imageUrl']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
