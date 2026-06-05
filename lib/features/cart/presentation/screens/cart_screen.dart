import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/cart_item_model.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const double _shippingFee = 0;
  static const double _discount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().loadCart();
      }
    });
  }

  Future<void> _increaseItem(CartItemModel item) async {
    final provider = context.read<CartProvider>();
    final success = await provider.increaseItem(item.id);
    _showUpdateResult(success, provider.errorMessage);
  }

  Future<void> _decreaseItem(CartItemModel item) async {
    final provider = context.read<CartProvider>();
    final success = await provider.decreaseItem(item.id);
    _showUpdateResult(success, provider.errorMessage);
  }

  Future<void> _removeItem(CartItemModel item) async {
    final provider = context.read<CartProvider>();
    final success = await provider.removeItem(item.id);
    _showUpdateResult(success, provider.errorMessage);
  }

  void _checkout() {
    final cart = context.read<CartProvider>().cart;
    final isEmpty = cart == null || cart.items.isEmpty;

    if (isEmpty) {
      _showSnackBar('Giỏ hàng của bạn đang trống');
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.selectAddress);
  }

  void _showUpdateResult(bool success, String? errorMessage) {
    if (!mounted || success) {
      return;
    }

    _showSnackBar(errorMessage ?? 'Không thể cập nhật giỏ hàng');
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CartProvider>();
    final cart = provider.cart;
    final items = cart?.items ?? const <CartItemModel>[];
    final totalPayment = ((cart?.totalAmount ?? 0) - _discount + _shippingFee)
        .clamp(0, double.infinity)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(centerTitle: true, title: const Text('Giỏ hàng')),
      body: RefreshIndicator(
        onRefresh: () => context.read<CartProvider>().loadCart(),
        child: provider.isLoading && cart == null
            ? const _LoadingView()
            : provider.errorMessage != null && cart == null
            ? _ErrorView(
                message: provider.errorMessage!,
                onRetry: () => context.read<CartProvider>().loadCart(),
              )
            : items.isEmpty
            ? const _EmptyCartView()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  for (final item in items) ...[
                    _CartItemCard(
                      item: item,
                      isUpdating: provider.isUpdating,
                      onIncrease: () => _increaseItem(item),
                      onDecrease: () => _decreaseItem(item),
                      onRemove: () => _removeItem(item),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (cart?.hasPrescriptionProduct ?? false) ...[
                    const _PrescriptionWarning(),
                    const SizedBox(height: 16),
                  ],
                  _OrderSummary(
                    totalItems: cart?.totalItems ?? 0,
                    subtotal: cart?.totalAmount ?? 0,
                    discount: _discount,
                    shippingFee: _shippingFee,
                    totalPayment: totalPayment,
                  ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
          child: ElevatedButton.icon(
            onPressed: provider.isUpdating ? null : _checkout,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Tiến hành đặt hàng'),
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isUpdating,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItemModel item;
  final bool isUpdating;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 94,
                height: 94,
                color: AppTheme.lightBlue,
                child: item.productImage == null
                    ? const Icon(
                        Icons.medication_liquid_outlined,
                        color: AppTheme.primaryBlue,
                        size: 42,
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
                          size: 42,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                            if (item.requiresPrescription) ...[
                              const _PrescriptionBadge(),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa sản phẩm',
                        onPressed: isUpdating ? null : onRemove,
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          CurrencyFormatter.format(item.unitPrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.darkBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _QuantityStepper(
                        quantity: item.quantity,
                        isUpdating: isUpdating,
                        onIncrease: onIncrease,
                        onDecrease: onDecrease,
                      ),
                    ],
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.isUpdating,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final bool isUpdating;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E0F2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Giảm số lượng',
            onPressed: isUpdating ? null : onDecrease,
            icon: const Icon(Icons.remove),
            color: AppTheme.textSecondary,
          ),
          SizedBox(
            width: 34,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tăng số lượng',
            onPressed: isUpdating ? null : onIncrease,
            icon: const Icon(Icons.add),
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.totalItems,
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.totalPayment,
  });

  final int totalItems;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double totalPayment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tóm tắt đơn hàng',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            _SummaryRow(label: 'Tổng sản phẩm', value: '$totalItems sản phẩm'),
            _SummaryRow(
              label: 'Tạm tính',
              value: CurrencyFormatter.format(subtotal),
            ),
            _SummaryRow(
              label: 'Giảm giá tạm thời',
              value: CurrencyFormatter.format(discount),
              valueColor: AppTheme.error,
            ),
            _SummaryRow(
              label: 'Phí giao hàng tạm thời',
              value: shippingFee == 0
                  ? '0đ'
                  : CurrencyFormatter.format(shippingFee),
              valueColor: AppTheme.success,
            ),
            const Divider(height: 30),
            _SummaryRow(
              label: 'Tổng thanh toán',
              value: CurrencyFormatter.format(totalPayment),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
    final style = TextStyle(
      color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style.copyWith(
              color: valueColor ?? (isTotal ? AppTheme.darkBlue : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionWarning extends StatelessWidget {
  const _PrescriptionWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Giỏ hàng có sản phẩm cần đơn thuốc. Bạn cần tải đơn thuốc khi đặt hàng.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionBadge extends StatelessWidget {
  const _PrescriptionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Cần đơn thuốc',
        style: TextStyle(
          color: Color(0xFFB42318),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        const Icon(
          Icons.shopping_cart_outlined,
          color: AppTheme.primaryBlue,
          size: 76,
        ),
        const SizedBox(height: 18),
        const Text(
          'Giỏ hàng của bạn đang trống',
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
          'Không tải được giỏ hàng',
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
