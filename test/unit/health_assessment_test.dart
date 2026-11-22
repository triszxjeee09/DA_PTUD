import 'package:an_tam_pharma/features/health/domain/health_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BMI', () {
    test('tính BMI và phân loại theo chuẩn châu Á', () {
      final bmi = HealthAssessor.bmi(170, 65)!;
      expect(bmi, closeTo(22.49, 0.01));
      expect(HealthAssessor.assessBmi(bmi).label, 'Bình thường');
      expect(HealthAssessor.assessBmi(17).level, HealthLevel.watch);
      expect(HealthAssessor.assessBmi(24).label, 'Thừa cân');
      expect(HealthAssessor.assessBmi(31).seeDoctor, isTrue);
    });

    test('dữ liệu không hợp lệ trả về null', () {
      expect(HealthAssessor.bmi(0, 60), isNull);
      expect(HealthAssessor.bmi(null, 60), isNull);
      expect(HealthAssessor.bmi(170, -1), isNull);
    });
  });

  group('Huyết áp', () {
    test('các ngưỡng', () {
      expect(HealthAssessor.assessBloodPressure(118, 76).level, HealthLevel.normal);
      expect(HealthAssessor.assessBloodPressure(135, 80).label, 'Bình thường cao');
      expect(HealthAssessor.assessBloodPressure(150, 95).seeDoctor, isTrue);
      expect(HealthAssessor.assessBloodPressure(185, 100).label, contains('rất cao'));
      expect(HealthAssessor.assessBloodPressure(85, 55).label, 'Huyết áp thấp');
    });
  });

  group('Đường huyết', () {
    test('đo lúc đói', () {
      expect(HealthAssessor.assessGlucose(95).level, HealthLevel.normal);
      expect(HealthAssessor.assessGlucose(110).label, contains('tiền đái tháo đường'));
      expect(HealthAssessor.assessGlucose(130).seeDoctor, isTrue);
      expect(HealthAssessor.assessGlucose(65).seeDoctor, isTrue);
    });

    test('quy đổi mmol/L và đo sau ăn', () {
      expect(HealthAssessor.assessGlucose(7.2, unit: 'mmol/L').level, HealthLevel.alert);
      expect(HealthAssessor.assessGlucose(150, fasting: false).level, HealthLevel.watch);
    });
  });
}
