class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.referenceId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _readString(json['id']),
      title: _readString(json['title']),
      content: _readString(json['content']),
      type: _readString(json['type']),
      referenceId: _readNullableString(json['referenceId']),
      isRead: _readBool(json['isRead']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
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

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    return fallback;
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
