class OrderStatusHistoryModel {
  const OrderStatusHistoryModel({
    required this.id,
    required this.status,
    required this.statusLabel,
    this.note,
    this.changedByName,
    this.createdAt,
  });

  final String id;
  final String status;
  final String statusLabel;
  final String? note;
  final String? changedByName;
  final DateTime? createdAt;

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      id: _readString(json['id']),
      status: _readString(json['status']),
      statusLabel: _readString(json['statusLabel']),
      note: _readNullableString(json['note']),
      changedByName: _readNullableString(json['changedByName']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'statusLabel': statusLabel,
      'note': note,
      'changedByName': changedByName,
      'createdAt': createdAt?.toIso8601String(),
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
}
