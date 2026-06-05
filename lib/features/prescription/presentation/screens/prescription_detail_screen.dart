import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/prescription_image_model.dart';
import '../../data/models/prescription_model.dart';
import '../../providers/prescription_provider.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  const PrescriptionDetailScreen({super.key, this.prescriptionId});

  final String? prescriptionId;

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.prescriptionId;
      if (mounted && id != null && id.isNotEmpty) {
        final provider = context.read<PrescriptionProvider>();
        if (provider.selectedPrescription?.id != id) {
          provider.clearSelectedPrescription();
        }
        provider.loadPrescriptionDetail(id);
      }
    });
  }

  void _continueShopping() {
    Navigator.of(context).pushNamed(AppRoutes.productList);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final prescription = provider.selectedPrescription;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn thuốc')),
      body: _buildBody(provider, prescription),
      bottomNavigationBar: prescription?.status == 'APPROVED'
          ? _ApprovedAction(onPressed: _continueShopping)
          : null,
    );
  }

  Widget _buildBody(
    PrescriptionProvider provider,
    PrescriptionModel? prescription,
  ) {
    if (provider.isLoading && prescription == null) {
      return const AppLoading(message: 'Đang tải chi tiết đơn thuốc...');
    }

    if (prescription == null) {
      return _ErrorView(
        message: provider.errorMessage ?? 'Không tìm thấy đơn thuốc.',
        onRetry: () {
          final id = widget.prescriptionId;
          if (id != null && id.isNotEmpty) {
            context.read<PrescriptionProvider>().loadPrescriptionDetail(id);
          }
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final id = widget.prescriptionId ?? prescription.id;
        if (id.isNotEmpty) {
          await context.read<PrescriptionProvider>().loadPrescriptionDetail(id);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _HeaderCard(prescription: prescription),
          const SizedBox(height: 14),
          _PrescriptionImages(images: prescription.images),
          const SizedBox(height: 14),
          _NotesCard(prescription: prescription),
          const SizedBox(height: 14),
          _StatusMessage(prescription: prescription),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.prescription});

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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.patientName.isEmpty
                            ? 'Bệnh nhân chưa cập nhật'
                            : prescription.patientName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _PrescriptionStatusChip(
                        status: prescription.status,
                        label: _statusLabel(prescription),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: prescription.patientPhone ?? 'Chưa cập nhật',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Ngày gửi',
              value: _formatDateTime(prescription.createdAt),
            ),
            if (prescription.reviewedAt != null) ...[
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.verified_outlined,
                label: 'Thời gian duyệt',
                value: _formatDateTime(prescription.reviewedAt),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrescriptionImages extends StatelessWidget {
  const _PrescriptionImages({required this.images});

  final List<PrescriptionImageModel> images;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ảnh đơn thuốc',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (images.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Chưa có ảnh đơn thuốc'),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final image = images[index];
                  return InkWell(
                    onTap: () => _showImagePreview(context, image.imageUrl),
                    borderRadius: BorderRadius.circular(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: image.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(
                          color: AppTheme.lightBlue,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: AppTheme.lightBlue,
                          child: Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(
                    height: 320,
                    child: Center(
                      child: Text(
                        'Không tải được ảnh',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.prescription});

  final PrescriptionModel prescription;

  @override
  Widget build(BuildContext context) {
    final customerNote = prescription.note?.trim();
    final pharmacistNote = prescription.pharmacistNote?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ghi chú', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _NoteBlock(
              title: 'Ghi chú của khách hàng',
              content: customerNote == null || customerNote.isEmpty
                  ? 'Không có ghi chú'
                  : customerNote,
            ),
            const SizedBox(height: 12),
            _NoteBlock(
              title: 'Ghi chú của dược sĩ',
              content: pharmacistNote == null || pharmacistNote.isEmpty
                  ? 'Dược sĩ chưa có ghi chú'
                  : pharmacistNote,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.prescription});

  final PrescriptionModel prescription;

  @override
  Widget build(BuildContext context) {
    if (prescription.status == 'REJECTED') {
      return _MessageBox(
        color: AppTheme.error,
        icon: Icons.cancel_outlined,
        title: 'Đơn thuốc bị từ chối',
        message: prescription.pharmacistNote?.trim().isNotEmpty == true
            ? prescription.pharmacistNote!.trim()
            : 'Dược sĩ chưa cập nhật lý do từ chối.',
      );
    }

    if (prescription.status == 'PENDING') {
      return const _MessageBox(
        color: AppTheme.warning,
        icon: Icons.hourglass_top_outlined,
        title: 'Đang chờ kiểm tra',
        message: 'Đơn thuốc đang chờ dược sĩ kiểm tra.',
      );
    }

    if (prescription.status == 'APPROVED') {
      return const _MessageBox(
        color: AppTheme.success,
        icon: Icons.check_circle_outline,
        title: 'Đơn thuốc đã được duyệt',
        message: 'Bạn có thể tiếp tục đặt hàng với đơn thuốc này.',
      );
    }

    return const SizedBox.shrink();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedAction extends StatelessWidget {
  const _ApprovedAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          child: const Text('Tiếp tục đặt hàng'),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.primaryBlue,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionStatusChip extends StatelessWidget {
  const _PrescriptionStatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'PENDING' => AppTheme.warning,
      'APPROVED' => AppTheme.success,
      'REJECTED' => AppTheme.error,
      _ => AppTheme.textSecondary,
    };

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

  return switch (prescription.status) {
    'PENDING' => 'Chờ duyệt',
    'APPROVED' => 'Đã duyệt',
    'REJECTED' => 'Từ chối',
    _ => 'Đang cập nhật',
  };
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Đang cập nhật';
  }

  return DateFormatter.formatDateTime(value);
}
