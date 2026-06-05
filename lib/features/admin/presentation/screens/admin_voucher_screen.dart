import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../voucher/data/models/voucher_model.dart';
import '../../providers/admin_voucher_provider.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final _searchController = TextEditingController();
  bool _didStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AdminVoucherProvider>().loadVouchers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({String? voucherId}) async {
    final shouldRefresh = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminVoucherForm,
      arguments: voucherId == null ? null : {'voucherId': voucherId},
    );

    if (!mounted || shouldRefresh != true) {
      return;
    }

    await context.read<AdminVoucherProvider>().loadVouchers();
  }

  Future<void> _submitSearch() {
    return context.read<AdminVoucherProvider>().loadVouchers(
      keyword: _searchController.text,
    );
  }

  Future<void> _confirmDelete(VoucherModel voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ẩn voucher'),
          content: Text(
            'Bạn có chắc chắn muốn ẩn voucher "${voucher.code}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ẩn'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminVoucherProvider>();
    final success = await provider.deleteVoucher(voucher.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã ẩn voucher'
              : provider.errorMessage ?? 'Không thể ẩn voucher.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý voucher')),
      body: Consumer<AdminVoucherProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => provider.loadVouchers(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _VoucherToolbar(
                  controller: _searchController,
                  isLoading: provider.isLoading,
                  onSearch: _submitSearch,
                  onChanged: () => setState(() {}),
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.vouchers.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải voucher...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.vouchers.isEmpty)
                  _VoucherErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadVouchers(),
                  )
                else if (provider.vouchers.isEmpty)
                  const _VoucherEmptyView()
                else ...[
                  if (provider.isLoading || provider.isDeleting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ...provider.vouchers.map(
                    (voucher) => _VoucherCard(
                      voucher: voucher,
                      isBusy: provider.isDeleting,
                      onEdit: () => _openForm(voucherId: voucher.id),
                      onDelete: () => _confirmDelete(voucher),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PaginationBar(provider: provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VoucherToolbar extends StatelessWidget {
  const _VoucherToolbar({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onSearch;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Tìm mã voucher',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      controller.clear();
                      onSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('+ Thêm voucher'),
        ),
      ],
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final VoucherModel voucher;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.code,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                _StatusChip(isActive: voucher.isActive),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: _discountTypeText(voucher.discountType)),
                _InfoChip(label: _discountValueText(voucher)),
                _InfoChip(
                  label:
                      'Đơn tối thiểu ${CurrencyFormatter.format(voucher.minOrderAmount)}',
                ),
                _InfoChip(
                  label:
                      'Đã dùng ${voucher.usedCount}/${voucher.usageLimit?.toString() ?? '∞'}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.event_available_rounded,
              text:
                  'Bắt đầu: ${_formatDate(voucher.startDate)} - Kết thúc: ${_formatDate(voucher.endDate)}',
            ),
            if ((voucher.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                voucher.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.visibility_off_rounded),
                    label: const Text('Ẩn'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _discountTypeText(String value) {
    return value == 'PERCENT' ? 'Giảm theo %' : 'Giảm tiền';
  }

  String _discountValueText(VoucherModel voucher) {
    if (voucher.discountType == 'PERCENT') {
      final maxDiscount = voucher.maxDiscountAmount;
      final suffix = maxDiscount == null
          ? ''
          : ', tối đa ${CurrencyFormatter.format(maxDiscount)}';
      return 'Giảm ${voucher.discountValue.toStringAsFixed(0)}%$suffix';
    }

    return 'Giảm ${CurrencyFormatter.format(voucher.discountValue)}';
  }

  String _formatDate(DateTime? value) {
    return value == null ? 'Chưa có' : DateFormatter.formatDate(value);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Đang hoạt động' : 'Đã ẩn'),
      visualDensity: VisualDensity.compact,
      backgroundColor: isActive
          ? AppTheme.success.withValues(alpha: 0.12)
          : AppTheme.textSecondary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: isActive ? AppTheme.success : AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.provider});

  final AdminVoucherProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: provider.isLoading || provider.isFirstPage
              ? null
              : provider.previousPage,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Trang trước',
        ),
        Expanded(
          child: Text(
            'Trang ${provider.page + 1}/${provider.totalPages} - ${provider.totalElements} voucher',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: provider.isLoading || provider.isLastPage
              ? null
              : provider.nextPage,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Trang sau',
        ),
      ],
    );
  }
}

class _VoucherErrorView extends StatelessWidget {
  const _VoucherErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.error,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoucherEmptyView extends StatelessWidget {
  const _VoucherEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: Text('Chưa có voucher phù hợp.', textAlign: TextAlign.center),
      ),
    );
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
