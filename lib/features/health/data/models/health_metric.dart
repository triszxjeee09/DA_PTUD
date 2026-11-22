import '../../domain/health_assessment.dart';

/// Một lần đo chỉ số sức khỏe: cân nặng, huyết áp hoặc đường huyết.
class HealthMetric {
  const HealthMetric({
    required this.id,
    required this.memberId,
    required this.type,
    required this.value,
    required this.measuredAt,
    this.value2,
    this.unit = '',
    this.note = '',
    this.fasting = true,
  });

  static const String weight = 'WEIGHT';
  static const String bloodPressure = 'BLOOD_PRESSURE';
  static const String glucose = 'GLUCOSE';

  static const Map<String, String> typeLabels = {
    weight: 'Cân nặng',
    bloodPressure: 'Huyết áp',
    glucose: 'Đường huyết',
  };

  static String defaultUnit(String type) {
    switch (type) {
      case weight:
        return 'kg';
      case bloodPressure:
        return 'mmHg';
      default:
        return 'mg/dL';
    }
  }

  final String id;
  final String memberId;
  final String type;

  /// Cân nặng / tâm thu / đường huyết.
  final double value;

  /// Tâm trương (chỉ dùng cho huyết áp).
  final double? value2;
  final String unit;
  final DateTime measuredAt;
  final String note;
  final bool fasting;

  String get displayValue {
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    if (type == bloodPressure) {
      return '${fmt(value)}/${fmt(value2 ?? 0)} $unit';
    }
    return '${fmt(value)} $unit';
  }

  /// Đánh giá nhanh; cân nặng cần chiều cao nên trả về `null`.
  HealthAssessment? get assessment {
    switch (type) {
      case bloodPressure:
        return HealthAssessor.assessBloodPressure(
          value.round(),
          (value2 ?? 0).round(),
        );
      case glucose:
        return HealthAssessor.assessGlucose(
          value,
          unit: unit,
          fasting: fasting,
        );
      default:
        return null;
    }
  }

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? weight).toString();
    return HealthMetric(
      id: json['id'].toString(),
      memberId: (json['memberId'] ?? '').toString(),
      type: type,
      value: double.tryParse(json['value'].toString()) ?? 0,
      value2: json['value2'] == null
          ? null
          : double.tryParse(json['value2'].toString()),
      unit: (json['unit'] ?? defaultUnit(type)).toString(),
      measuredAt:
          DateTime.tryParse((json['measuredAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      note: (json['note'] ?? '').toString(),
      fasting: json['fasting'] is bool ? json['fasting'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'type': type,
      'value': value,
      'value2': value2,
      'unit': unit,
      'measuredAt': measuredAt.toUtc().toIso8601String(),
      'note': note,
      'fasting': fasting,
    };
  }
}
