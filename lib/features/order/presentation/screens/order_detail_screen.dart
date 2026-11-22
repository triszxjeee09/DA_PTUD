import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../payment/providers/payment_provider.dart';
import '../../data/models/order_detail_model.dart';
import '../../data/models/order_item_model.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, this.orderId, this.order});

  final String? orderId;
  final OrderDetailModel? order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? get _orderId {
    final id = widget.orderId ?? widget.order?.id;
    if (id == null || id.trim().isEmpty) {
      return null;
    }

    return id;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final orderId = _orderId;
      if (orderId != null) {
        context.read<OrderProvider>().loadOrderDetail(orderId);
      }
    });
  }

  Future<void> _cancelOrder(OrderDetailModel order) async {
    final reason = await _showCancelDialog();
    if (reason == null || reason.trim().isEmpty || !mounted) {
      return;
    }

    final provider = context.read<OrderProvider>();
    final success = await provider.cancelOrder(order.id, reason.trim());

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Hủy đơn hàng thành công')),
      );
      await provider.loadOrderDetail(order.id);
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Không thể hủy đơn hàng'),
      ),
    );
  }

  Future<String?> _showCancelDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hủy đơn hàng'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do hủy đơn hàng',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _trackOrder(OrderDetailModel order) {
    Navigator.of(context).pushNamed(
      AppRoutes.orderTracking,
      arguments: {'orderId': order.orderCode, 'order': order},
    );
  }

  void _reviewProduct(OrderDetailModel order, OrderItemModel item) {
    final productId = item.productId;
    if (productId == null || productId.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Không tìm thấy sản phẩm để đánh giá')),
        );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.writeReview,
      arguments: {
        'productId': productId,
        'productName': item.productName,
        'productImage': item.productImage,
        'orderId': order.id,
        'unitPrice': item.unitPrice,
      },
    );
  }

  // ignore: unused_element
  void _reviewOrder() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Chức năng đang phát triển')),
      );
  }

  Future<void> _retryVnPayPayment(OrderDetailModel order) async {
    final paymentProvider = context.read<PaymentProvider>();
    final success = await paymentProvider.createVnPayPayment(order.id);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar(
        paymentProvider.errorMessage ?? 'Không thể tạo thanh toán VNPay',
      );
      return;
    }

    final vnPayPayment = paymentProvider.vnPayPayment;
    final paymentUrl = vnPayPayment?.paymentUrl.trim() ?? '';
    if (paymentUrl.isEmpty) {
      _showSnackBar('Không tìm thấy đường dẫn thanh toán VNPay');
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.paymentVnPay,
      arguments: {
        'paymentUrl': paymentUrl,
        'orderId': order.id,
        'orderCode': order.orderCode,
      },
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final loadedOrder = provider.selectedOrder;
    final order = loadedOrder?.id == _orderId ? loadedOrder : widget.order;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: provider.isLoading && order == null
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? _EmptyDetailView(message: provider.errorMessage)
          : RefreshIndicator(
              onRefresh: () async {
                final orderId = _orderId;
                if (orderId != null) {
                  await context.read<OrderProvider>().loadOrderDetail(orderId);
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                children: [
                  _OrderHeaderCard(order: order),
                  const SizedBox(height: 16),
                  _ShippingInfoCard(order: order),
                  const SizedBox(height: 16),
                  _ProductsCard(
                    items: order.items,
                    canReview: order.orderStatus == 'DELIVERED',
                    onReview: (item) => _reviewProduct(order, item),
                  ),
                  const SizedBox(height: 16),
                  _OrderPaymentCard(
                    order: order,
                    isCreatingPayment: paymentProvider.isCreatingVnPayPayment,
                    onRetryPayment: () => _retryVnPayPayment(order),
                  ),
                  if (order.note != null && order.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _NoteCard(note: order.note!),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: order == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: _OrderActions(
                  order: order,
                  isCancelling: provider.isCreating,
                  onTrack: () => _trackOrder(order),
                  onCancel: () => _cancelOrder(order),
                ),
              ),
            ),
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final OrderDetailModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InfoLine(label: 'Mã đơn hàng', value: order.orderCode),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Trạng thái',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                _OrderStatusChip(
                  label: _statusLabel(order),
                  status: order.orderStatus,
                ),
              ],
            ),
            if (order.createdAt != null) ...[
              const Divider(height: 24),
              _InfoLine(
                label: 'Ngày đặt',
                value: DateFormatter.formatDateTime(order.createdAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _statusLabel(OrderDetailModel order) {
    if (order.orderStatusLabel.isNotEmpty) {
      return order.orderStatusLabel;
    }

    return switch (order.orderStatus) {
      'PENDING' => 'Chờ xác nhận',
      'CONFIRMED' => 'Đã xác nhận',
      'WAITING_PRESCRIPTION' => 'Chờ đơn thuốc',
      'PREPARING' => 'Đang chuẩn bị',
      'SHIPPING' => 'Đang giao',
      'DELIVERED' => 'Đã giao',
      'CANCELLED' => 'Đã hủy',
      _ => 'Đang cập nhật',
    };
  }
}

class _ShippingInfoCard extends StatelessWidget {
  const _ShippingInfoCard({required this.order});

  final OrderDetailModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin giao hàng',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    [order.receiverName, order.receiverPhone]
                        .where(
                          (value) => value != null && value.trim().isNotEmpty,
                        )
                        .join(' | '),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.shippingAddress ?? 'Đang cập nhật địa chỉ giao hàng',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({
    required this.items,
    required this.canReview,
    required this.onReview,
  });

  final List<OrderItemModel> items;
  final bool canReview;
  final ValueChanged<OrderItemModel> onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm đã mua',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text(
                'Chưa có thông tin sản phẩm',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              for (final item in items) ...[
                _OrderProductItem(
                  item: item,
                  canReview: canReview,
                  onReview: () => onReview(item),
                ),
                if (item != items.last) const Divider(height: 24),
              ],
          ],
        ),
      ),
    );
  }
}

class _OrderProductItem extends StatelessWidget {
  const _OrderProductItem({
    required this.item,
    required this.canReview,
    required this.onReview,
  });

  final OrderItemModel item;
  final bool canReview;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 82,
            height: 82,
            color: AppTheme.lightBlue,
            child: item.productImage == null
                ? const Icon(
                    Icons.medication_liquid_outlined,
                    color: AppTheme.primaryBlue,
                    size: 40,
                  )
                : CachedNetworkImage(
                    imageUrl: item.productImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.medication_liquid_outlined,
                      color: AppTheme.primaryBlue,
                      size: 40,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Số lượng: x${item.quantity}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Đơn giá: ${CurrencyFormatter.format(item.unitPrice)}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(item.totalPrice),
              style: const TextStyle(
                color: AppTheme.darkBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (canReview) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onReview,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Đánh giá'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _OrderPaymentCard extends StatelessWidget {
  const _OrderPaymentCard({
    required this.order,
    required this.isCreatingPayment,
    required this.onRetryPayment,
  });

  final OrderDetailModel order;
  final bool isCreatingPayment;
  final VoidCallback onRetryPayment;

  bool get _canRetryVnPayPayment {
    return order.paymentMethod == 'VNPAY' &&
        {'PENDING', 'FAILED'}.contains(order.paymentStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thanh toán',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _InfoLine(
              label: 'Phương thức thanh toán',
              value: _paymentMethodLabel(order.paymentMethod),
            ),
            _InfoLine(
              label: 'Trạng thái thanh toán',
              value: _paymentStatusLabel(order.paymentStatus),
            ),
            if (_canRetryVnPayPayment) ...[
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: isCreatingPayment ? null : onRetryPayment,
                icon: isCreatingPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment_outlined),
                label: Text(
                  isCreatingPayment ? 'Đang xử lý...' : 'Thanh toán lại',
                ),
              ),
            ],
            const Divider(height: 26),
            _InfoLine(
              label: 'Tạm tính',
              value: CurrencyFormatter.format(order.totalAmount),
            ),
            _InfoLine(
              label: 'Giảm giá',
              value: CurrencyFormatter.format(order.discountAmount),
              valueColor: AppTheme.error,
            ),
            _InfoLine(
              label: 'Phí giao hàng',
              value: CurrencyFormatter.format(order.shippingFee),
            ),
            const Divider(height: 26),
            _InfoLine(
              label: 'Tổng thanh toán',
              value: CurrencyFormatter.format(order.finalAmount),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(String value) {
    return switch (value) {
      'COD' => 'COD',
      'VNPAY' => 'VNPay',
      'MOMO' => 'MoMo',
      'BANK_TRANSFER' => 'Chuyển khoản ngân hàng',
      _ => 'Đang cập nhật',
    };
  }

  String _paymentStatusLabel(String value) {
    return switch (value) {
      'PAID' => 'Đã thanh toán',
      'PENDING' => 'Chờ thanh toán',
      'FAILED' => 'Thanh toán thất bại',
      'REFUNDED' => 'Đã hoàn tiền',
      'UNPAID' => 'Chờ thanh toán',
      _ => value.isEmpty ? 'Đang cập nhật' : value,
    };
  }
}

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.order});

  final OrderDetailModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thanh toán',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _InfoLine(
              label: 'Phương thức thanh toán',
              value: _paymentMethodLabel(order.paymentMethod),
            ),
            _InfoLine(
              label: 'Trạng thái thanh toán',
              value: _paymentStatusLabel(order.paymentStatus),
            ),
            const Divider(height: 26),
            _InfoLine(
              label: 'Tạm tính',
              value: CurrencyFormatter.format(order.totalAmount),
            ),
            _InfoLine(
              label: 'Giảm giá',
              value: CurrencyFormatter.format(order.discountAmount),
              valueColor: AppTheme.error,
            ),
            _InfoLine(
              label: 'Phí giao hàng',
              value: CurrencyFormatter.format(order.shippingFee),
            ),
            const Divider(height: 26),
            _InfoLine(
              label: 'Tổng thanh toán',
              value: CurrencyFormatter.format(order.finalAmount),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(String value) {
    return switch (value) {
      'COD' => 'Thanh toán khi nhận hàng',
      'VNPAY' => 'VNPay',
      'MOMO' => 'MoMo',
      'BANK_TRANSFER' => 'Chuyển khoản ngân hàng',
      _ => 'Đang cập nhật',
    };
  }

  String _paymentStatusLabel(String value) {
    return switch (value) {
      'PAID' => 'Đã thanh toán',
      'UNPAID' => 'Chưa thanh toán',
      'PENDING' => 'Đang chờ',
      'FAILED' => 'Thanh toán thất bại',
      'REFUNDED' => 'Đã hoàn tiền',
      _ => value.isEmpty ? 'Đang cập nhật' : value,
    };
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              note,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.order,
    required this.isCancelling,
    required this.onTrack,
    required this.onCancel,
  });

  final OrderDetailModel order;
  final bool isCancelling;
  final VoidCallback onTrack;
  final VoidCallback onCancel;

  Future<void> _reorder(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cart = context.read<CartProvider>();
    try {
      final result = JsonApi.asMap(
        await JsonApi().post('/orders/${order.id}/reorder'),
      );
      await cart.loadCart();
      messenger.showSnackBar(
        SnackBar(
          content: Text((result['message'] ?? 'Đã thêm vào giỏ hàng').toString()),
          action: SnackBarAction(
            label: 'Xem giỏ',
            onPressed: () => navigator.pushNamed(AppRoutes.cart),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(JsonApi.message(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = const {
      'PENDING',
      'CONFIRMED',
      'WAITING_PRESCRIPTION',
    }.contains(order.orderStatus);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: onTrack,
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Theo dõi đơn hàng'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.invoice,
                  arguments: {'orderId': order.id},
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Hóa đơn'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reorder(context),
                icon: const Icon(Icons.replay),
                label: const Text('Mua lại'),
              ),
            ),
          ],
        ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isCancelling ? null : onCancel,
            icon: isCancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text('Hủy đơn hàng'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: isTotal ? 17 : 15,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    valueColor ??
                    (isTotal ? AppTheme.darkBlue : AppTheme.textPrimary),
                fontSize: isTotal ? 22 : 15,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
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
      'WAITING_PRESCRIPTION' => AppTheme.warning,
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

class _EmptyDetailView extends StatelessWidget {
  const _EmptyDetailView({this.message});

  final String? message;

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
            const Text(
              'Chưa có thông tin đơn hàng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            if (message != null && message!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
