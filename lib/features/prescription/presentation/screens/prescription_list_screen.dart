import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/prescription_model.dart';
import '../../providers/prescription_provider.dart';

enum _PrescriptionFilter {
  all('Tất cả', null),
  pending('Chờ duyệt', 'PENDING'),
  approved('Đã duyệt', 'APPROVED'),
  rejected('Từ chối', 'REJECTED');

  const _PrescriptionFilter(this.label, this.status);

  final String label;
  final String? status;
}

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  late final ScrollController _scrollController;

  _PrescriptionFilter _selectedFilter = _PrescriptionFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPrescriptions(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      final provider = context.read<PrescriptionProvider>();
      if (provider.hasMore && !provider.isLoading && !provider.isLoadingMore) {
        _loadPrescriptions();
      }
    }
  }

  Future<void> _loadPrescriptions({bool refresh = false}) {
    return context.read<PrescriptionProvider>().loadMyPrescriptions(
      status: _selectedFilter.status,
      refresh: refresh,
    );
  }

  void _selectFilter(_PrescriptionFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() => _selectedFilter = filter);
    _loadPrescriptions(refresh: true);
  }

  void _openUpload() {
    Navigator.of(context).pushNamed(AppRoutes.prescriptionUpload);
  }

  void _openDetail(String id) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.prescriptionDetail, arguments: {'id': id});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn thuốc của tôi')),
      body: Column(
        children: [
          _FilterBar(selected: _selectedFilter, onSelected: _selectFilter),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPrescriptions(refresh: true),
              child: _buildBody(provider),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUpload,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('+ Gửi đơn thuốc'),
      ),
    );
  }

  Widget _buildBody(PrescriptionProvider provider) {
    if (provider.isLoading && provider.prescriptions.isEmpty) {
      return const AppLoading(message: 'Đang tải đơn thuốc...');
    }

    if (provider.errorMessage != null && provider.prescriptions.isEmpty) {
      return _ListErrorView(
        message: provider.errorMessage!,
        onRetry: () => _loadPrescriptions(refresh: true),
      );
    }

    if (provider.prescriptions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
        children: [
          const AppEmptyState(
            title: 'Bạn chưa gửi đơn thuốc nào',
            message:
                'Gửi ảnh đơn thuốc để dược sĩ kiểm tra và tư vấn sản phẩm phù hợp.',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _openUpload,
            child: const Text('Gửi đơn thuốc'),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount:
          provider.prescriptions.length + (provider.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= provider.prescriptions.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final prescription = provider.prescriptions[index];
        return _PrescriptionCard(
          prescription: prescription,
          onTap: () => _openDetail(prescription.id),
        );
      },
    );
  }
}

class _ListErrorView extends StatelessWidget {
  const _ListErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final _PrescriptionFilter selected;
  final ValueChanged<_PrescriptionFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _PrescriptionFilter.values.map((filter) {
            final isSelected = selected == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) => onSelected(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.prescription, required this.onTap});

  final PrescriptionModel prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final note = prescription.note?.trim();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PrescriptionStatusChip(
                    status: prescription.status,
                    label: _statusLabel(prescription),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: 'Ngày gửi: ${_formatDateTime(prescription.createdAt)}',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.image_outlined,
                text: '${prescription.images.length} ảnh đơn thuốc',
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Xem chi tiết'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(PrescriptionModel prescription) {
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

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Đang cập nhật';
    }

    return DateFormatter.formatDateTime(value);
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
