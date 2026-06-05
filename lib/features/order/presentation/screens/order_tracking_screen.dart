import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/order_detail_model.dart';
import '../../data/models/order_status_history_model.dart';
import '../../providers/order_provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, this.orderId, this.order});

  final String? orderId;
  final OrderDetailModel? order;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String? get _trackingOrderKey {
    return _resolveTrackingOrderKey(context.read<OrderProvider>());
  }

  String? _resolveTrackingOrderKey(OrderProvider provider) {
    final selectedOrder = widget.order ?? provider.selectedOrder;
    final explicitId = widget.orderId?.trim();
    final selectedOrderCode = selectedOrder?.orderCode.trim();
    final selectedOrderId = selectedOrder?.id.trim();

    if (explicitId != null && explicitId.isNotEmpty) {
      if (explicitId.startsWith('ORD')) {
        return explicitId;
      }

      if (selectedOrderId == explicitId &&
          selectedOrderCode != null &&
          selectedOrderCode.isNotEmpty) {
        return selectedOrderCode;
      }

      return explicitId;
    }

    if (selectedOrderCode != null && selectedOrderCode.isNotEmpty) {
      return selectedOrderCode;
    }

    if (selectedOrderId != null && selectedOrderId.isNotEmpty) {
      return selectedOrderId;
    }

    return null;
  }

  String? get _detailOrderId {
    final id =
        widget.orderId ??
        widget.order?.id ??
        context.read<OrderProvider>().selectedOrder?.id;
    if (id == null || id.trim().isEmpty || id.trim().startsWith('ORD')) {
      return null;
    }

    return id.trim();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTracking();
      }
    });
  }

  Future<void> _loadTracking() async {
    final trackingOrderKey = _trackingOrderKey;
    if (trackingOrderKey == null) {
      return;
    }

    final provider = context.read<OrderProvider>();
    await provider.loadStatusHistory(trackingOrderKey);

    final detailOrderId = _detailOrderId;
    if (mounted && provider.selectedOrder == null && detailOrderId != null) {
      await provider.loadOrderDetail(detailOrderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final order = provider.selectedOrder ?? widget.order;
    final histories = _sortedHistories(provider.statusHistories);
    final trackingOrderKey = _resolveTrackingOrderKey(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Theo dõi đơn hàng')),
      body: RefreshIndicator(
        onRefresh: _loadTracking,
        child: provider.isLoading && histories.isEmpty
            ? const _LoadingView()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  _OrderCodeCard(
                    orderCode: order?.orderCode ?? trackingOrderKey,
                  ),
                  const SizedBox(height: 18),
                  if (provider.errorMessage != null && histories.isEmpty)
                    _ErrorMessage(message: provider.errorMessage!)
                  else if (histories.isEmpty)
                    const _EmptyHistoryView()
                  else
                    _TimelineCard(histories: histories),
                ],
              ),
      ),
    );
  }

  List<OrderStatusHistoryModel> _sortedHistories(
    List<OrderStatusHistoryModel> histories,
  ) {
    final sorted = [...histories];
    sorted.sort((a, b) {
      final left = a.createdAt;
      final right = b.createdAt;
      if (left == null && right == null) {
        return 0;
      }
      if (left == null) {
        return 1;
      }
      if (right == null) {
        return -1;
      }

      return left.compareTo(right);
    });

    return sorted;
  }
}

class _OrderCodeCard extends StatelessWidget {
  const _OrderCodeCard({required this.orderCode});

  final String? orderCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mã đơn hàng',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    orderCode == null || orderCode!.isEmpty
                        ? 'Đang cập nhật'
                        : orderCode!,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.histories});

  final List<OrderStatusHistoryModel> histories;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        child: Column(
          children: [
            for (var index = 0; index < histories.length; index++)
              _TimelineStep(
                history: histories[index],
                isFirst: index == 0,
                isLast: index == histories.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.history,
    required this.isFirst,
    required this.isLast,
  });

  final OrderStatusHistoryModel history;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: isFirst ? 0 : 16,
                child: const VerticalDivider(
                  width: 2,
                  thickness: 2,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(history.status),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              if (!isLast)
                const SizedBox(
                  height: 64,
                  child: VerticalDivider(
                    width: 2,
                    thickness: 2,
                    color: AppTheme.primaryBlue,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: isFirst ? 8 : 24,
              bottom: isLast ? 0 : 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(history),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (history.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.formatDateTime(history.createdAt!),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (history.note != null &&
                    history.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    history.note!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (history.changedByName != null &&
                    history.changedByName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật bởi: ${history.changedByName}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static IconData _statusIcon(String status) {
    return switch (status) {
      'PENDING' => Icons.assignment_outlined,
      'CONFIRMED' => Icons.check_circle_outline,
      'WAITING_PRESCRIPTION' => Icons.description_outlined,
      'PREPARING' => Icons.inventory_2_outlined,
      'SHIPPING' => Icons.local_shipping_outlined,
      'DELIVERED' => Icons.home_outlined,
      'CANCELLED' => Icons.cancel_outlined,
      _ => Icons.radio_button_checked,
    };
  }

  static String _statusLabel(OrderStatusHistoryModel history) {
    if (history.statusLabel.trim().isNotEmpty) {
      return history.statusLabel;
    }

    return switch (history.status) {
      'PENDING' => 'Chờ xác nhận',
      'CONFIRMED' => 'Đã xác nhận',
      'WAITING_PRESCRIPTION' => 'Chờ đơn thuốc',
      'PREPARING' => 'Đang chuẩn bị hàng',
      'SHIPPING' => 'Đang giao hàng',
      'DELIVERED' => 'Giao hàng thành công',
      'CANCELLED' => 'Đã hủy',
      _ => 'Đang cập nhật',
    };
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Chưa có lịch sử trạng thái',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: AppTheme.primaryBlue,
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tải được lịch sử đơn hàng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
