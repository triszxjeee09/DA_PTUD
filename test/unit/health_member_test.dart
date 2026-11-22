import 'package:an_tam_pharma/features/health/data/models/health_member.dart';
import 'package:an_tam_pharma/features/health/data/models/health_metric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HealthMember tính tuổi theo ngày sinh', () {
    const member = HealthMember(id: 'm1', name: 'Mẹ', relation: 'MOTHER', birthDate: '1970-12-01');
    expect(member.ageAt(DateTime(2026, 11, 22)), 55);
    expect(member.ageAt(DateTime(2026, 12, 1)), 56);
    expect(member.relationLabel, 'Mẹ');
    expect(const HealthMember(id: 'x', name: 'A').ageAt(DateTime.now()), isNull);
  });

  test('HealthMetric hiển thị và đánh giá huyết áp', () {
    final metric = HealthMetric.fromJson({
      'id': 'h1',
      'memberId': 'm1',
      'type': 'BLOOD_PRESSURE',
      'value': 150,
      'value2': 95,
      'measuredAt': '2026-11-20T01:00:00+00:00',
    });
    expect(metric.displayValue, '150/95 mmHg');
    expect(metric.assessment!.seeDoctor, isTrue);
    expect(HealthMetric.fromJson(metric.toJson()).value2, 95);
  });
}
