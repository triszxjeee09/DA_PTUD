import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/health_assessment.dart';

/// Thẻ hiển thị kết quả đánh giá chỉ số sức khỏe.
class AssessmentCard extends StatelessWidget {
  const AssessmentCard({super.key, required this.assessment});

  final HealthAssessment assessment;

  Color get _color {
    switch (assessment.level) {
      case HealthLevel.normal:
        return AppTheme.success;
      case HealthLevel.watch:
        return AppTheme.warning;
      case HealthLevel.alert:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                assessment.level == HealthLevel.normal
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assessment.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(assessment.advice, style: const TextStyle(height: 1.4)),
          if (assessment.seeDoctor) ...[
            const SizedBox(height: 8),
            const Text(
              'Gợi ý: nên đi khám hoặc liên hệ dược sĩ/bác sĩ để được tư vấn.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            HealthAssessor.disclaimer,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
