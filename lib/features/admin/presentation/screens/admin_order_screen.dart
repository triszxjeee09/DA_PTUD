import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../order/data/models/order_model.dart';
import '../../providers/admin_order_provider.dart';
import '../widgets/admin_empty_view.dart';
import '../widgets/admin_filter_chip.dart';
import '../widgets/admin_status_chip.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  bool _didStart = false;

  static const _filters = [
    _StatusFilter('Tất cả', null),
    _StatusFilter('Chờ xác nhận', 'PENDING'),
    _StatusFilter('Đã xác nhận', 'CONFIRMED'),
    _StatusFilter('Đang chuẩn bị', 'PREPARING'),
    _StatusFilter('Đang giao', 'SHIPPING'),
    _StatusFilter('Đã giao', 'DELIVERED'),
    _StatusFilter('Đã hủy', 'CANCELLED'),
  ];

  static const _updateStatuses = [
    _StatusFilter('Đã xác nhận', 'CONFIRMED'),
    _StatusFilter('Đang chuẩn bị', 'PREPARING'),
    _StatusFilter('Đang giao', 'SHIPPING'),
    _StatusFilter('Đã giao', 'DELIVERED'),
    _StatusFilter('Đã hủy', 'CANCELLED'),
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
      context.read<AdminOrderProvider>().loadOrders();
    });
  }

  Future<void> _showUpdateStatus(OrderModel order) async {
    final status = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Cập nhật trạng thái',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ..._updateStatuses.map(
                (item) => ListTile(
                  leading: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text(item.label),
                  onTap: () => Navigator.of(context).pop(item.value),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (status == null || !mounted) return;

    final provider = context.read<AdminOrderProvider>();
    final success = await provider.updateOrderStatus(order.id, status);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã cập nhật trạng thái đơn hàng.'
              : provider.errorMessage ?? 'Không thể cập nhật trạng thái.',
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showDetail(OrderModel order) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(order.orderCode),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailLine(
                  label: 'Khách hàng',
                  value: _text(order.customerName),
                ),
                _DetailLine(
                  label: 'Người nhận',
                  value: _text(order.receiverName),
                ),
                _DetailLine(label: 'SĐT', value: _text(order.receiverPhone)),
                _DetailLine(
                  label: 'Địa chỉ',
                  value: _text(order.shippingAddress),
                ),
                _DetailLine(label: 'Thanh toán', value: order.paymentStatus),
                _DetailLine(
                  label: 'Tổng tiền',
                  value: CurrencyFormatter.format(order.finalAmount),
                ),
              ],
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
      appBar: AppBar(title: const Text('Quản lý đơn hàng')),
      body: Consumer<AdminOrderProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () =>
                provider.loadOrders(status: provider.selectedStatus),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _FilterChips(
                  filters: _filters,
                  selectedStatus: provider.selectedStatus,
                  onSelected: (status) => provider.loadOrders(status: status),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.orders.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải đơn hàng...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.orders.isEmpty)
                  _ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () =>
                        provider.loadOrders(status: provider.selectedStatus),
                  )
                else if (provider.orders.isEmpty)
                  const _EmptyView(message: 'Chưa có đơn hàng phù hợp.')
                else ...[
                  if (provider.isLoading || provider.isUpdating)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        color: AppTheme.primaryBlue,
                        minHeight: 3,
                      ),
                    ),
                  ...provider.orders.map(
                    (order) => _OrderCard(
                      order: order,
                      isBusy: provider.isUpdating,
                      onDetail: () => Navigator.of(context).pushNamed(
                        AppRoutes.adminOrderDetail,
                        arguments: {'orderId': order.id},
                      ),
                      onUpdateStatus: () => _showUpdateStatus(order),
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

  String _text(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Chưa có' : text;
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isBusy,
    required this.onDetail,
    required this.onUpdateStatus,
  });

  final OrderModel order;
  final bool isBusy;
  final VoidCallback onDetail;
  final VoidCallback onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final createdAt = order.createdAt == null
        ? 'Chưa có'
        : DateFormatter.formatDateTime(order.createdAt!);

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
                    order.orderCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AdminStatusChip(
                  status: order.orderStatus,
                  label: order.orderStatusLabel.isEmpty
                      ? order.orderStatus
                      : order.orderStatusLabel,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoText(label: 'Khách hàng', value: _text(order.customerName)),
            _InfoText(label: 'Ngày đặt', value: createdAt),
            _InfoText(
              label: 'Tổng tiền',
              value: CurrencyFormatter.format(order.finalAmount),
            ),
            _InfoText(label: 'Thanh toán', value: order.paymentStatus),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Chi tiết'),
                ),
                ElevatedButton.icon(
                  onPressed: isBusy ? null : onUpdateStatus,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Cập nhật trạng thái'),
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
        final selected = filter.value == selectedStatus;
        return AdminFilterChip(
          selected: selected,
          label: filter.label,
          onTap: () => onSelected(filter.value),
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
    return SizedBox(
      height: 320,
      child: AdminEmptyView(message: message, icon: Icons.receipt_long_rounded),
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
