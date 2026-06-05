import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../prescription/data/models/prescription_model.dart';
import '../../providers/admin_prescription_provider.dart';

class AdminPrescriptionScreen extends StatefulWidget {
  const AdminPrescriptionScreen({super.key});

  @override
  State<AdminPrescriptionScreen> createState() =>
      _AdminPrescriptionScreenState();
}

class _AdminPrescriptionScreenState extends State<AdminPrescriptionScreen> {
  bool _didStart = false;

  static const _filters = [
    _StatusFilter('Tất cả', null),
    _StatusFilter('Chờ duyệt', 'PENDING'),
    _StatusFilter('Đã duyệt', 'APPROVED'),
    _StatusFilter('Từ chối', 'REJECTED'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStart) return;
    _didStart = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!(context.read<AuthProvider>().currentUser?.isAdmin ?? false)) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        return;
      }
      context.read<AdminPrescriptionProvider>().loadPrescriptions();
    });
  }

  Future<void> _approve(PrescriptionModel prescription) async {
    final provider = context.read<AdminPrescriptionProvider>();
    final success = await provider.reviewPrescription(
      id: prescription.id,
      status: 'APPROVED',
    );
    if (!mounted) return;
    _showResult(success, provider.errorMessage, 'Đã duyệt đơn thuốc.');
  }

  Future<void> _reject(PrescriptionModel prescription) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Từ chối đơn thuốc'),
          content: TextField(
            controller: noteController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Nhập lý do từ chối'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(noteController.text),
              child: const Text('Từ chối'),
            ),
          ],
        );
      },
    );

    noteController.dispose();
    if (note == null || !mounted) return;

    final provider = context.read<AdminPrescriptionProvider>();
    final success = await provider.reviewPrescription(
      id: prescription.id,
      status: 'REJECTED',
      pharmacistNote: note,
    );
    if (!mounted) return;
    _showResult(success, provider.errorMessage, 'Đã từ chối đơn thuốc.');
  }

  void _showResult(bool success, String? errorMessage, String successMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : errorMessage ?? 'Thao tác không thành công.',
        ),
      ),
    );
  }

  void _showImages(PrescriptionModel prescription) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(prescription.patientName),
          content: SizedBox(
            width: double.maxFinite,
            child: prescription.images.isEmpty
                ? const Text('Đơn thuốc chưa có ảnh.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: prescription.images.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final image = prescription.images[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 160,
                              color: AppTheme.lightBlue,
                              alignment: Alignment.center,
                              child: const Text('Không tải được ảnh'),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );
    if (!isAdmin) return const _NoPermissionView();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đơn thuốc')),
      body: Consumer<AdminPrescriptionProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () =>
                provider.loadPrescriptions(status: provider.selectedStatus),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _FilterChips(
                  filters: _filters,
                  selectedStatus: provider.selectedStatus,
                  onSelected: (status) =>
                      provider.loadPrescriptions(status: status),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.prescriptions.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải đơn thuốc...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.prescriptions.isEmpty)
                  _ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadPrescriptions(
                      status: provider.selectedStatus,
                    ),
                  )
                else if (provider.prescriptions.isEmpty)
                  const _EmptyView(message: 'Chưa có đơn thuốc phù hợp.')
                else ...[
                  if (provider.isLoading || provider.isReviewing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        color: AppTheme.primaryBlue,
                        minHeight: 3,
                      ),
                    ),
                  ...provider.prescriptions.map(
                    (prescription) => _PrescriptionCard(
                      prescription: prescription,
                      isBusy: provider.isReviewing,
                      onView: () => _showImages(prescription),
                      onApprove: () => _approve(prescription),
                      onReject: () => _reject(prescription),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.isBusy,
    required this.onView,
    required this.onApprove,
    required this.onReject,
  });

  final PrescriptionModel prescription;
  final bool isBusy;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final createdAt = prescription.createdAt == null
        ? 'Chưa có'
        : DateFormatter.formatDateTime(prescription.createdAt!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prescription.patientName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    prescription.statusLabel.isEmpty
                        ? prescription.status
                        : prescription.statusLabel,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoText(
              label: 'Khách hàng',
              value: _text(prescription.customerName),
            ),
            _InfoText(label: 'Ngày gửi', value: createdAt),
            _InfoText(
              label: 'Số ảnh',
              value: prescription.images.length.toString(),
            ),
            if (prescription.pharmacistNote?.trim().isNotEmpty ?? false)
              _InfoText(label: 'Ghi chú', value: prescription.pharmacistNote!),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Xem'),
                ),
                ElevatedButton.icon(
                  onPressed: isBusy ? null : onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Duyệt'),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Từ chối'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _text(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Chưa có' : text;
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selectedStatus,
    required this.onSelected,
  });

  final List<_StatusFilter> filters;
  final String? selectedStatus;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        return ChoiceChip(
          selected: filter.value == selectedStatus,
          label: Text(filter.label),
          onSelected: (_) => onSelected(filter.value),
        );
      }).toList(),
    );
  }
}

class _StatusFilter {
  const _StatusFilter(this.label, this.value);
  final String label;
  final String? value;
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text('$label: $value'),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 320, child: Center(child: Text(message)));
  }
}

class _NoPermissionView extends StatelessWidget {
  const _NoPermissionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Bạn không có quyền truy cập khu vực Admin.')),
    );
  }
}
