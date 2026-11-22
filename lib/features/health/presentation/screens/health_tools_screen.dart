import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../data/models/health_metric.dart';
import '../../domain/health_assessment.dart';
import '../widgets/assessment_card.dart';

/// Công cụ sức khỏe: tính BMI và lối vào các màn hình theo dõi chỉ số.
class HealthToolsScreen extends StatefulWidget {
  const HealthToolsScreen({super.key});

  @override
  State<HealthToolsScreen> createState() => _HealthToolsScreenState();
}

class _HealthToolsScreenState extends State<HealthToolsScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  double? _bmi;
  String? _error;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final bmi = HealthAssessor.bmi(height, weight);
    setState(() {
      if (bmi == null || height! < 50 || height > 250 || weight! > 400) {
        _bmi = null;
        _error = 'Vui lòng nhập chiều cao (cm) và cân nặng (kg) hợp lệ';
      } else {
        _bmi = bmi;
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Công cụ sức khỏe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tính chỉ số BMI',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Chiều cao (cm)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cân nặng (kg)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _calculate,
                      child: const Text('Tính BMI'),
                    ),
                  ),
                  if (bmi != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'BMI = ${bmi.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AssessmentCard(assessment: HealthAssessor.assessBmi(bmi)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ToolTile(
            icon: Icons.family_restroom_outlined,
            title: 'Hồ sơ sức khỏe gia đình',
            subtitle: 'Quản lý hồ sơ, dị ứng, bệnh nền của người thân',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.healthProfile),
          ),
          _ToolTile(
            icon: Icons.favorite_outline,
            title: 'Theo dõi huyết áp',
            subtitle: 'Ghi nhận, xem biểu đồ và nhận gợi ý',
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.healthMetric,
              arguments: {'type': HealthMetric.bloodPressure},
            ),
          ),
          _ToolTile(
            icon: Icons.bloodtype_outlined,
            title: 'Theo dõi đường huyết',
            subtitle: 'Ghi nhận lúc đói / sau ăn',
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.healthMetric,
              arguments: {'type': HealthMetric.glucose},
            ),
          ),
          _ToolTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Theo dõi cân nặng',
            subtitle: 'Theo dõi thay đổi cân nặng và BMI',
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.healthMetric,
              arguments: {'type': HealthMetric.weight},
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            HealthAssessor.disclaimer,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightBlue,
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
