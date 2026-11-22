/// Mức độ đánh giá chỉ số sức khỏe.
enum HealthLevel { normal, watch, alert }

class HealthAssessment {
  const HealthAssessment({
    required this.level,
    required this.label,
    required this.advice,
    this.seeDoctor = false,
  });

  final HealthLevel level;
  final String label;
  final String advice;

  /// `true` khi nên đi khám / liên hệ nhân viên y tế.
  final bool seeDoctor;
}

/// Công cụ đánh giá nhanh BMI, huyết áp, đường huyết.
///
/// Ngưỡng mang tính tham khảo (BMI theo chuẩn châu Á - Thái Bình Dương, huyết
/// áp theo khuyến cáo chung, đường huyết theo tiêu chuẩn đường huyết đói).
class HealthAssessor {
  const HealthAssessor._();

  static const String disclaimer =
      'Kết quả chỉ mang tính tham khảo, không thay thế chẩn đoán của bác sĩ.';

  static double? bmi(double? heightCm, double? weightKg) {
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      return null;
    }
    final meters = heightCm / 100;
    return weightKg / (meters * meters);
  }

  static HealthAssessment assessBmi(double bmi) {
    if (bmi < 18.5) {
      return const HealthAssessment(
        level: HealthLevel.watch,
        label: 'Thiếu cân',
        advice: 'Nên bổ sung dinh dưỡng cân đối và theo dõi cân nặng định kỳ.',
      );
    }
    if (bmi < 23) {
      return const HealthAssessment(
        level: HealthLevel.normal,
        label: 'Bình thường',
        advice: 'Hãy duy trì chế độ ăn uống và vận động hiện tại.',
      );
    }
    if (bmi < 25) {
      return const HealthAssessment(
        level: HealthLevel.watch,
        label: 'Thừa cân',
        advice: 'Nên tăng vận động, hạn chế đồ ngọt và chất béo bão hòa.',
      );
    }
    if (bmi < 30) {
      return const HealthAssessment(
        level: HealthLevel.alert,
        label: 'Béo phì độ I',
        advice: 'Nên xây dựng kế hoạch giảm cân và tham khảo ý kiến dược sĩ.',
      );
    }
    return const HealthAssessment(
      level: HealthLevel.alert,
      label: 'Béo phì độ II',
      advice: 'Nên đi khám để được tư vấn chế độ ăn và điều trị phù hợp.',
      seeDoctor: true,
    );
  }

  static HealthAssessment assessBloodPressure(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return const HealthAssessment(
        level: HealthLevel.alert,
        label: 'Tăng huyết áp rất cao',
        advice:
            'Hãy nghỉ ngơi và đo lại sau 5 phút. Nếu vẫn cao hoặc kèm đau ngực, '
            'khó thở, nhức đầu dữ dội, hãy đến cơ sở y tế/gọi cấp cứu ngay.',
        seeDoctor: true,
      );
    }
    if (systolic >= 140 || diastolic >= 90) {
      return const HealthAssessment(
        level: HealthLevel.alert,
        label: 'Huyết áp cao',
        advice:
            'Nên đo lại vào các thời điểm khác nhau và đi khám để được tư vấn.',
        seeDoctor: true,
      );
    }
    if (systolic < 90 || diastolic < 60) {
      return const HealthAssessment(
        level: HealthLevel.watch,
        label: 'Huyết áp thấp',
        advice:
            'Uống đủ nước, đứng dậy từ từ. Nếu chóng mặt, ngất hoặc mệt kéo dài '
            'hãy đi khám.',
        seeDoctor: true,
      );
    }
    if (systolic >= 130 || diastolic >= 85) {
      return const HealthAssessment(
        level: HealthLevel.watch,
        label: 'Bình thường cao',
        advice:
            'Giảm muối, tập thể dục đều đặn và theo dõi huyết áp thường xuyên.',
      );
    }
    return const HealthAssessment(
      level: HealthLevel.normal,
      label: 'Bình thường',
      advice:
          'Huyết áp trong ngưỡng bình thường, hãy tiếp tục lối sống lành mạnh.',
    );
  }

  /// [unit] là `mg/dL` hoặc `mmol/L`. [fasting] = đo lúc đói.
  static HealthAssessment assessGlucose(
    double value, {
    String unit = 'mg/dL',
    bool fasting = true,
  }) {
    final mgdl = unit.toLowerCase().contains('mmol') ? value * 18 : value;
    if (mgdl < 54) {
      return const HealthAssessment(
        level: HealthLevel.alert,
        label: 'Hạ đường huyết nặng',
        advice: 'Cần xử trí ngay (ăn/uống đường nhanh nếu còn tỉnh) và đến cơ sở y tế.',
        seeDoctor: true,
      );
    }
    if (mgdl < 70) {
      return const HealthAssessment(
        level: HealthLevel.alert,
        label: 'Đường huyết thấp',
        advice: 'Nên bổ sung đường hấp thu nhanh và đo lại sau 15 phút.',
        seeDoctor: true,
      );
    }
    if (fasting) {
      if (mgdl < 100) {
        return const HealthAssessment(
          level: HealthLevel.normal,
          label: 'Bình thường',
          advice: 'Đường huyết đói trong ngưỡng bình thường.',
        );
      }
      if (mgdl < 126) {
        return const HealthAssessment(
          level: HealthLevel.watch,
          label: 'Nguy cơ tiền đái tháo đường',
          advice: 'Nên điều chỉnh chế độ ăn, vận động và kiểm tra lại định kỳ.',
        );
      }
      return const HealthAssessment(
        level: HealthLevel.alert,
        label: 'Đường huyết cao',
        advice: 'Nên đi khám để được xét nghiệm và tư vấn điều trị.',
        seeDoctor: true,
      );
    }
    if (mgdl < 140) {
      return const HealthAssessment(
        level: HealthLevel.normal,
        label: 'Bình thường',
        advice: 'Đường huyết sau ăn trong ngưỡng bình thường.',
      );
    }
    if (mgdl < 200) {
      return const HealthAssessment(
        level: HealthLevel.watch,
        label: 'Hơi cao',
        advice: 'Hạn chế đồ ngọt, theo dõi thêm và kiểm tra lúc đói.',
      );
    }
    return const HealthAssessment(
      level: HealthLevel.alert,
      label: 'Đường huyết cao',
      advice: 'Nên đi khám để được xét nghiệm và tư vấn điều trị.',
      seeDoctor: true,
    );
  }
}
