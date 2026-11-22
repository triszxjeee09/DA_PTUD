import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/health_metric.dart';
import '../../domain/health_assessment.dart';
import '../../providers/health_provider.dart';
import '../widgets/assessment_card.dart';
import '../widgets/metric_chart.dart';

/// Ghi nhận và theo dõi một loại chỉ số (huyết áp / đường huyết / cân nặng).
class HealthMetricScreen extends StatefulWidget {
  const HealthMetricScreen({super.key, required this.type, this.memberId});

  final String type;
  final String? memberId;

  @override
  State<HealthMetricScreen> createState() => _HealthMetricScreenState();
}

class _HealthMetricScreenState extends State<HealthMetricScreen> {
  final TextEditingController _value = TextEditingController();
  final TextEditingController _value2 = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String? _memberId;
  String _glucoseUnit = 'mg/dL';
  bool _fasting = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _memberId = widget.memberId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final owner = context.read<AuthProvider>().currentUser?.id;
      if (owner == null) {
        return;
      }
      final provider = context.read<HealthProvider>();
      await provider.load(owner);
      if (!mounted) {
        return;
      }
      setState(() {
        _memberId ??= provider.members.isEmpty
            ? null
            : provider.members.first.id;
      });
    });
  }

  @override
  void dispose() {
    _value.dispose();
    _value2.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _title =>
      'Theo dõi ${HealthMetric.typeLabels[widget.type]!.toLowerCase()}';

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final memberId = _memberId;
    if (memberId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chưa có hồ sơ thành viên')),
      );
      return;
    }
    final value = double.tryParse(_value.text.trim().replaceAll(',', '.'));
    final value2 = double.tryParse(_value2.text.trim().replaceAll(',', '.'));
    final error = _validate(value, value2);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _saving = true);
    final metric = HealthMetric(
      id: 'hmt-${DateTime.now().microsecondsSinceEpoch}',
      memberId: memberId,
      type: widget.type,
      value: value!,
      value2: widget.type == HealthMetric.bloodPressure ? value2 : null,
      unit: widget.type == HealthMetric.glucose
          ? _glucoseUnit
          : HealthMetric.defaultUnit(widget.type),
      measuredAt: DateTime.now(),
      note: _note.text.trim(),
      fasting: _fasting,
    );
    await context.read<HealthProvider>().addMetric(metric);
    if (!mounted) {
      return;
    }
    _value.clear();
    _value2.clear();
    _note.clear();
    setState(() => _saving = false);
    messenger.showSnackBar(const SnackBar(content: Text('Đã lưu chỉ số')));
  }

  String? _validate(double? value, double? value2) {
    switch (widget.type) {
      case HealthMetric.bloodPressure:
        if (value == null || value2 == null) {
          return 'Vui lòng nhập huyết áp tâm thu và tâm trương';
        }
        if (value < 50 ||
            value > 280 ||
            value2 < 30 ||
            value2 > 200 ||
            value2 >= value) {
          return 'Giá trị huyết áp không hợp lệ (tâm thu phải lớn hơn tâm trương)';
        }
        return null;
      case HealthMetric.glucose:
        if (value == null || value <= 0) {
          return 'Vui lòng nhập chỉ số đường huyết';
        }
        final mgdl = _glucoseUnit == 'mmol/L' ? value * 18 : value;
        return mgdl < 10 || mgdl > 900
            ? 'Giá trị đường huyết không hợp lệ'
            : null;
      default:
        return value == null || value < 2 || value > 400
            ? 'Cân nặng không hợp lệ'
            : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();
    final members = provider.members;
    final memberId = _memberId;
    final member = provider.memberById(memberId);
    final metrics = memberId == null
        ? <HealthMetric>[]
        : provider.metricsOf(memberId, widget.type);
    final latest = metrics.isEmpty ? null : metrics.first;

    HealthAssessment? assessment = latest?.assessment;
    String? extraLine;
    if (widget.type == HealthMetric.weight && latest != null) {
      final bmi = HealthAssessor.bmi(member?.heightCm, latest.value);
      if (bmi != null) {
        assessment = HealthAssessor.assessBmi(bmi);
        extraLine = 'BMI hiện tại: ${bmi.toStringAsFixed(1)}';
      } else {
        extraLine = 'Cập nhật chiều cao trong hồ sơ để tính BMI.';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (members.length > 1)
            DropdownButtonFormField<String>(
              initialValue: members.any((m) => m.id == memberId)
                  ? memberId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Thành viên',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                for (final m in members)
                  DropdownMenuItem(
                    value: m.id,
                    child: Text('${m.name} (${m.relationLabel})'),
                  ),
              ],
              onChanged: (value) => setState(() => _memberId = value),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghi nhận mới',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (widget.type == HealthMetric.bloodPressure)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _value,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tâm thu (mmHg)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _value2,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tâm trương (mmHg)',
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: _value,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.type == HealthMetric.weight
                            ? 'Cân nặng (kg)'
                            : 'Đường huyết ($_glucoseUnit)',
                      ),
                    ),
                  if (widget.type == HealthMetric.glucose) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('mg/dL'),
                          selected: _glucoseUnit == 'mg/dL',
                          onSelected: (_) =>
                              setState(() => _glucoseUnit = 'mg/dL'),
                        ),
                        ChoiceChip(
                          label: const Text('mmol/L'),
                          selected: _glucoseUnit == 'mmol/L',
                          onSelected: (_) =>
                              setState(() => _glucoseUnit = 'mmol/L'),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đo lúc đói'),
                      value: _fasting,
                      onChanged: (value) => setState(() => _fasting = value),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _note,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Đang lưu...' : 'Lưu chỉ số'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (latest != null) ...[
            const SizedBox(height: 14),
            Text(
              'Lần đo gần nhất: ${latest.displayValue}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            if (extraLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  extraLine,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            const SizedBox(height: 8),
            if (assessment != null) AssessmentCard(assessment: assessment),
          ],
          if (metrics.length >= 2) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biểu đồ gần đây',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: MetricChart(
                        primary: metrics
                            .take(20)
                            .toList()
                            .reversed
                            .map((m) => m.value)
                            .toList(),
                        secondary: widget.type == HealthMetric.bloodPressure
                            ? metrics
                                  .take(20)
                                  .toList()
                                  .reversed
                                  .map((m) => m.value2 ?? 0)
                                  .toList()
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Lịch sử (${metrics.length})',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          for (final metric in metrics.take(30))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                metric.displayValue,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${metric.measuredAt.day.toString().padLeft(2, '0')}/${metric.measuredAt.month.toString().padLeft(2, '0')}/${metric.measuredAt.year} '
                '${metric.measuredAt.hour.toString().padLeft(2, '0')}:${metric.measuredAt.minute.toString().padLeft(2, '0')}'
                '${metric.assessment == null ? '' : ' • ${metric.assessment!.label}'}',
              ),
              trailing: IconButton(
                tooltip: 'Xóa',
                onPressed: () =>
                    context.read<HealthProvider>().deleteMetric(metric.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
        ],
      ),
    );
  }
}
