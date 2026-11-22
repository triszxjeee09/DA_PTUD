/// Lịch nhắc uống thuốc. Không phụ thuộc Flutter để dễ kiểm thử.
class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.times,
    required this.startDate,
    this.dosage = '',
    this.repeat = 'DAILY',
    this.weekdays = const [],
    this.endDate,
    this.note = '',
    this.memberId,
    this.memberName,
    this.isActive = true,
  });

  final String id;
  final String medicineName;
  final String dosage;

  /// Các giờ uống dạng `HH:mm`.
  final List<String> times;

  /// `DAILY` hoặc `WEEKLY`.
  final String repeat;

  /// Thứ trong tuần (1 = Thứ hai ... 7 = Chủ nhật) khi `repeat == WEEKLY`.
  final List<int> weekdays;

  /// Ngày bắt đầu/kết thúc dạng `yyyy-MM-dd`.
  final String startDate;
  final String? endDate;
  final String note;
  final String? memberId;
  final String? memberName;
  final bool isActive;

  static String dateKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  bool appliesOn(DateTime day) {
    if (!isActive) {
      return false;
    }
    final key = dateKey(day);
    if (key.compareTo(startDate) < 0) {
      return false;
    }
    final end = endDate;
    if (end != null && end.isNotEmpty && key.compareTo(end) > 0) {
      return false;
    }
    if (repeat == 'WEEKLY' && !weekdays.contains(day.weekday)) {
      return false;
    }
    return true;
  }

  MedicationReminder copyWith({
    String? medicineName,
    String? dosage,
    List<String>? times,
    String? repeat,
    List<int>? weekdays,
    String? startDate,
    String? endDate,
    bool clearEndDate = false,
    String? note,
    String? memberId,
    String? memberName,
    bool? isActive,
  }) {
    return MedicationReminder(
      id: id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      repeat: repeat ?? this.repeat,
      weekdays: weekdays ?? this.weekdays,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      note: note ?? this.note,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      isActive: isActive ?? this.isActive,
    );
  }

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    final times = json['times'];
    final weekdays = json['weekdays'];
    final end = json['endDate']?.toString();
    return MedicationReminder(
      id: json['id'].toString(),
      medicineName: (json['medicineName'] ?? '').toString(),
      dosage: (json['dosage'] ?? '').toString(),
      times: times is List ? times.map((e) => e.toString()).toList() : const [],
      repeat: json['repeat']?.toString() == 'WEEKLY' ? 'WEEKLY' : 'DAILY',
      weekdays: weekdays is List
          ? weekdays.map((e) => int.tryParse(e.toString()) ?? 0).toList()
          : const [],
      startDate: (json['startDate'] ?? dateKey(DateTime.now())).toString(),
      endDate: end == null || end.isEmpty ? null : end,
      note: (json['note'] ?? '').toString(),
      memberId: json['memberId']?.toString(),
      memberName: json['memberName']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'times': times,
      'repeat': repeat,
      'weekdays': weekdays,
      'startDate': startDate,
      'endDate': endDate,
      'note': note,
      'memberId': memberId,
      'memberName': memberName,
      'isActive': isActive,
    };
  }
}

/// Bản ghi đã uống / bỏ qua một liều.
class ReminderLog {
  const ReminderLog({
    required this.reminderId,
    required this.medicineName,
    required this.date,
    required this.time,
    required this.taken,
  });

  final String reminderId;
  final String medicineName;
  final String date;
  final String time;
  final bool taken;

  String get id => idFor(reminderId, date, time);

  static String idFor(String reminderId, String date, String time) {
    return '$reminderId:$date:$time';
  }

  factory ReminderLog.fromJson(Map<String, dynamic> json) {
    return ReminderLog(
      reminderId: (json['reminderId'] ?? '').toString(),
      medicineName: (json['medicineName'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      taken: json['taken'] is bool ? json['taken'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reminderId': reminderId,
      'medicineName': medicineName,
      'date': date,
      'time': time,
      'taken': taken,
    };
  }
}
