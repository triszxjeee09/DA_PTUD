import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_voucher_model.dart';
import '../../providers/admin_voucher_provider.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _statusFilter = 'all';
  bool _didStart = false;

  bool? get _isActiveFilter {
    return switch (_statusFilter) {
      'active' => true,
      'inactive' => false,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
  }

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

      _loadVouchers(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreIfNeeded);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers({required bool refresh}) {
    return context.read<AdminVoucherProvider>().loadVouchers(
      refresh: refresh,
      keyword: _searchController.text,
      isActive: _isActiveFilter,
    );
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > 420) {
      return;
    }

    final provider = context.read<AdminVoucherProvider>();
    if (!provider.hasMore ||
        provider.isLoading ||
        provider.isLoadingMore ||
        provider.isDeleting) {
      return;
    }

    _loadVouchers(refresh: false);
  }

  Future<void> _openForm({String? voucherId}) async {
    final normalizedVoucherId = voucherId?.trim();
    if (voucherId != null &&
        (normalizedVoucherId == null || normalizedVoucherId.isEmpty)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã voucher')),
      );
      return;
    }

    final shouldRefresh = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminVoucherForm,
      arguments: normalizedVoucherId == null
          ? null
          : {'voucherId': normalizedVoucherId},
    );

    if (!mounted || shouldRefresh != true) {
      return;
    }

    await _loadVouchers(refresh: true);
  }

  Future<void> _confirmDelete(AdminVoucherModel voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa voucher'),
          content: const Text('Bạn có chắc chắn muốn xóa voucher này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Xóa'),
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
              ? 'Xóa voucher thành công'
              : provider.errorMessage ?? 'Không thể xóa voucher',
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
      appBar: AppBar(
        title: const Text('Quản lý voucher'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => _loadVouchers(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<AdminVoucherProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => _loadVouchers(refresh: true),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _VoucherToolbar(
                  controller: _searchController,
                  selectedFilter: _statusFilter,
                  isLoading: provider.isLoading,
                  onSearch: () => _loadVouchers(refresh: true),
                  onFilterChanged: (value) {
                    setState(() => _statusFilter = value);
                    _loadVouchers(refresh: true);
                  },
                  onTextChanged: () => setState(() {}),
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
                    onRetry: () => _loadVouchers(refresh: true),
                  )
                else if (provider.vouchers.isEmpty)
                  const _VoucherEmptyView()
                else ...[
                  if (provider.isLoading ||
                      provider.isLoadingMore ||
                      provider.isDeleting)
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
                  _LoadMoreFooter(provider: provider),
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
    required this.selectedFilter,
    required this.isLoading,
    required this.onSearch,
    required this.onFilterChanged,
    required this.onTextChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String selectedFilter;
  final bool isLoading;
  final Future<void> Function() onSearch;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onTextChanged;
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
            hintText: 'Tìm mã hoặc tên voucher',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? IconButton(
                    tooltip: 'Tìm kiếm',
                    onPressed: onSearch,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  )
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      controller.clear();
                      onTextChanged();
                      onSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => onTextChanged(),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            selected: {selectedFilter},
            onSelectionChanged: isLoading
                ? null
                : (values) => onFilterChanged(values.first),
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tất cả')),
              ButtonSegment(value: 'active', label: Text('Đang hoạt động')),
              ButtonSegment(value: 'inactive', label: Text('Ngừng hoạt động')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm voucher'),
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

  final AdminVoucherModel voucher;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final description = voucher.description?.trim();

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
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
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
                if (voucher.maxDiscountAmount != null)
                  _InfoChip(
                    label:
                        'Giảm tối đa ${CurrencyFormatter.format(voucher.maxDiscountAmount!)}',
                  ),
                _InfoChip(label: _usageText(voucher)),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.event_available_rounded,
              text: 'Bắt đầu: ${_formatDate(voucher.startDate)}',
            ),
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.event_busy_rounded,
              text: 'Kết thúc: ${_formatDate(voucher.endDate)}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                    ),
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
    final type = value.trim().toUpperCase();
    return type == 'PERCENT' ? 'Giảm theo phần trăm' : 'Giảm tiền cố định';
  }

  String _discountValueText(AdminVoucherModel voucher) {
    if (voucher.discountType.trim().toUpperCase() == 'PERCENT') {
      return '${voucher.discountValue.toStringAsFixed(0)}%';
    }

    return CurrencyFormatter.format(voucher.discountValue);
  }

  String _usageText(AdminVoucherModel voucher) {
    final limit = voucher.usageLimit?.toString() ?? 'Không giới hạn';
    return 'Đã dùng ${voucher.usedCount}/$limit';
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
      label: Text(isActive ? 'Đang hoạt động' : 'Ngừng hoạt động'),
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

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.provider});

  final AdminVoucherProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (!provider.hasMore) {
      return Text(
        'Đã hiển thị tất cả voucher',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return const SizedBox(height: 32);
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
        child: Text('Chưa có voucher nào', textAlign: TextAlign.center),
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
