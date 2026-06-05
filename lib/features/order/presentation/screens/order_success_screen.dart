import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/order_detail_model.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.order, this.orderId});

  final OrderDetailModel? order;
  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final effectiveOrderId = order?.id ?? orderId ?? '';
    final userEmail = context.watch<AuthProvider>().currentUser?.email?.trim();
    final hasPrescriptionOrder =
        order?.prescriptionId?.trim().isNotEmpty == true;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppTheme.success,
                          size: 72,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Đặt hàng thành công!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cảm ơn bạn đã đặt hàng. Nhà thuốc sẽ sớm xác nhận đơn của bạn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _OrderInfoCard(order: order),
                      const SizedBox(height: 16),
                      _ConfirmationEmailCard(email: userEmail),
                      if (hasPrescriptionOrder) ...[
                        const SizedBox(height: 16),
                        const _PrescriptionOrderWarning(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: effectiveOrderId.isEmpty
                    ? null
                    : () => Navigator.of(context).pushNamed(
                        AppRoutes.orderDetail,
                        arguments: {
                          'orderId': effectiveOrderId,
                          if (order != null) 'order': order,
                        },
                      ),
                child: const Text('Xem chi tiết đơn hàng'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false),
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationEmailCard extends StatelessWidget {
  const _ConfirmationEmailCard({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = email?.trim();
    final hasEmail = normalizedEmail != null && normalizedEmail.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email xác nhận',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasEmail
                        ? 'Thông tin đơn hàng đã được gửi tới email $normalizedEmail. Vui lòng kiểm tra hộp thư đến hoặc thư rác.'
                        : 'Tài khoản của bạn chưa có email nên hệ thống chưa thể gửi email xác nhận đơn hàng.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (!hasEmail) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.accountProfile),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Cập nhật email'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionOrderWarning extends StatelessWidget {
  const _PrescriptionOrderWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.24)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.receipt_long_outlined, color: AppTheme.primaryBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đơn hàng có thuốc kê đơn. Dược sĩ sẽ kiểm tra đơn thuốc trước khi xử lý.',
              style: TextStyle(color: AppTheme.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});

  final OrderDetailModel? order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InfoRow(
              label: 'Mã đơn hàng',
              value: order?.orderCode.isNotEmpty == true
                  ? order!.orderCode
                  : 'Đang cập nhật',
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Tổng thanh toán',
              value: CurrencyFormatter.format(order?.finalAmount ?? 0),
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Phương thức thanh toán',
              value: _paymentLabel(order?.paymentMethod),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String? value) {
    return switch (value) {
      'COD' => 'Thanh toán khi nhận hàng',
      'VNPAY' => 'VNPay',
      'MOMO' => 'MoMo',
      'BANK_TRANSFER' => 'Chuyển khoản ngân hàng',
      _ => 'Đang cập nhật',
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
