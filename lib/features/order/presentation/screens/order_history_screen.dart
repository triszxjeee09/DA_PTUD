import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final ScrollController _scrollController;

  _OrderStatusFilter _selectedFilter = _OrderStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadOrders(refresh: true);
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
    final provider = context.read<OrderProvider>();
    if (position.pixels >= position.maxScrollExtent - 280 &&
        provider.hasMore &&
        !provider.isLoading &&
        !provider.isLoadingMore) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders({bool refresh = false}) {
    return context.read<OrderProvider>().loadMyOrders(
      status: _selectedFilter.status,
      refresh: refresh,
    );
  }

  void _selectFilter(_OrderStatusFilter filter) {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
    });
    _loadOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusFilterBar(
            selectedFilter: _selectedFilter,
            onSelected: _selectFilter,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadOrders(refresh: true),
              child: provider.isLoading && orders.isEmpty
                  ? const _LoadingView()
                  : provider.errorMessage != null && orders.isEmpty
                  ? _ErrorView(
                      message: provider.errorMessage!,
                      onRetry: () => _loadOrders(refresh: true),
                    )
                  : orders.isEmpty
                  ? const _EmptyOrdersView()
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      itemCount:
                          orders.length + (provider.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index >= orders.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final order = orders[index];
                        return _OrderCard(order: order);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.selectedFilter,
    required this.onSelected,
  });

  final _OrderStatusFilter selectedFilter;
  final ValueChanged<_OrderStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        itemCount: _OrderStatusFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _OrderStatusFilter.values[index];
          final selected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter.label),
            selected: selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isEmpty ? null : order.items.first;
    final itemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.createdAt == null
                            ? 'Đang cập nhật'
                            : DateFormatter.formatDate(order.createdAt!),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                _OrderStatusChip(
                  label: order.orderStatusLabel.isEmpty
                      ? _fallbackStatusLabel(order.orderStatus)
                      : order.orderStatusLabel,
                  status: order.orderStatus,
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 74,
                    height: 74,
                    color: AppTheme.lightBlue,
                    child: firstItem?.productImage == null
                        ? const Icon(
                            Icons.receipt_long_outlined,
                            color: AppTheme.primaryBlue,
                            size: 34,
                          )
                        : CachedNetworkImage(
                            imageUrl: firstItem!.productImage!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.receipt_long_outlined,
                              color: AppTheme.primaryBlue,
                              size: 34,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _productSummary(order),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemCount sản phẩm',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _paymentLabel(order.paymentMethod),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(order.finalAmount),
                  style: const TextStyle(
                    color: AppTheme.darkBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.orderDetail,
                  arguments: {'orderId': order.id},
                ),
                child: const Text('Xem chi tiết'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _productSummary(OrderModel order) {
    if (order.items.isEmpty) {
      return 'Sản phẩm: Đang cập nhật';
    }

    final firstName = order.items.first.productName;
    final otherCount = order.items.length - 1;
    if (otherCount <= 0) {
      return 'Sản phẩm: $firstName';
    }

    return 'Sản phẩm: $firstName và $otherCount sản phẩm khác';
  }

  String _paymentLabel(String value) {
    return switch (value) {
      'COD' => 'Thanh toán khi nhận hàng',
      'VNPAY' => 'VNPay',
      'MOMO' => 'MoMo',
      'BANK_TRANSFER' => 'Chuyển khoản ngân hàng',
      _ => 'Phương thức thanh toán: Đang cập nhật',
    };
  }

  String _fallbackStatusLabel(String status) {
    return switch (status) {
      'PENDING' => 'Chờ xác nhận',
      'CONFIRMED' => 'Đã xác nhận',
      'PREPARING' => 'Đang chuẩn bị',
      'SHIPPING' => 'Đang giao',
      'DELIVERED' => 'Đã giao',
      'CANCELLED' => 'Đã hủy',
      _ => 'Đang cập nhật',
    };
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'DELIVERED' => AppTheme.success,
      'CANCELLED' => AppTheme.error,
      'PENDING' => AppTheme.textSecondary,
      'CONFIRMED' => AppTheme.primaryBlue,
      'PREPARING' => AppTheme.warning,
      'SHIPPING' => AppTheme.primaryBlue,
      _ => AppTheme.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          color: AppTheme.primaryBlue,
          size: 76,
        ),
        const SizedBox(height: 18),
        const Text(
          'Bạn chưa có đơn hàng nào',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.productList,
            (route) => route.settings.name == AppRoutes.main,
          ),
          child: const Text('Mua sắm ngay'),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        const Icon(
          Icons.wifi_off_outlined,
          color: AppTheme.primaryBlue,
          size: 72,
        ),
        const SizedBox(height: 16),
        const Text(
          'Không tải được đơn hàng',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 22),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}

enum _OrderStatusFilter {
  all('Tất cả', null),
  pending('Chờ xác nhận', 'PENDING'),
  confirmed('Đã xác nhận', 'CONFIRMED'),
  preparing('Đang chuẩn bị', 'PREPARING'),
  shipping('Đang giao', 'SHIPPING'),
  delivered('Đã giao', 'DELIVERED'),
  cancelled('Đã hủy', 'CANCELLED');

  const _OrderStatusFilter(this.label, this.status);

  final String label;
  final String? status;
}
