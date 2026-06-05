import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/prescription_model.dart';
import '../../providers/prescription_provider.dart';

class SelectPrescriptionScreen extends StatefulWidget {
  const SelectPrescriptionScreen({super.key});

  @override
  State<SelectPrescriptionScreen> createState() =>
      _SelectPrescriptionScreenState();
}

class _SelectPrescriptionScreenState extends State<SelectPrescriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PrescriptionProvider>().loadMyPrescriptions(
          status: 'APPROVED',
          refresh: true,
        );
      }
    });
  }

  Future<void> _refresh() {
    return context.read<PrescriptionProvider>().loadMyPrescriptions(
      status: 'APPROVED',
      refresh: true,
    );
  }

  Future<void> _openUpload() async {
    await Navigator.of(context).pushNamed(AppRoutes.prescriptionUpload);

    if (!mounted) {
      return;
    }

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn đơn thuốc')),
      body: RefreshIndicator(onRefresh: _refresh, child: _buildBody(provider)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _openUpload,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('+ Gửi đơn thuốc mới'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PrescriptionProvider provider) {
    if (provider.isLoading && provider.prescriptions.isEmpty) {
      return const AppLoading(message: 'Đang tải đơn thuốc đã duyệt...');
    }

    if (provider.errorMessage != null && provider.prescriptions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppTheme.primaryBlue,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: _refresh, child: const Text('Thử lại')),
        ],
      );
    }

    if (provider.prescriptions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: const [
          AppEmptyState(
            title: 'Chưa có đơn thuốc đã duyệt',
            message: 'Bạn có thể gửi đơn thuốc mới để dược sĩ kiểm tra.',
            icon: Icons.receipt_long_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      itemCount: provider.prescriptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final prescription = provider.prescriptions[index];
        return _SelectablePrescriptionCard(prescription: prescription);
      },
    );
  }
}

class _SelectablePrescriptionCard extends StatelessWidget {
  const _SelectablePrescriptionCard({required this.prescription});

  final PrescriptionModel prescription;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    prescription.patientName.isEmpty
                        ? 'Bệnh nhân chưa cập nhật'
                        : prescription.patientName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  status: prescription.status,
                  label: _statusLabel(prescription),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: 'Ngày gửi: ${_formatDate(prescription.createdAt)}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.image_outlined,
              text: '${prescription.images.length} ảnh đơn thuốc',
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(prescription),
                child: const Text('Chọn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = status == 'APPROVED'
        ? AppTheme.success
        : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _statusLabel(PrescriptionModel prescription) {
  if (prescription.statusLabel.trim().isNotEmpty) {
    return prescription.statusLabel;
  }

  return prescription.status == 'APPROVED' ? 'Đã duyệt' : 'Đang cập nhật';
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return 'Đang cập nhật';
  }

  return DateFormatter.formatDateTime(value);
}
