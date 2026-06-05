import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../data/models/payment_model.dart';

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.success,
    this.payment,
    this.orderId,
    this.orderCode,
    this.paymentMethod,
    this.amount,
    this.transactionCode,
    this.message,
  });

  final bool success;
  final PaymentModel? payment;
  final String? orderId;
  final String? orderCode;
  final String? paymentMethod;
  final double? amount;
  final String? transactionCode;
  final String? message;

  String? get _effectiveOrderId {
    final id = payment?.orderId ?? orderId;
    if (id == null || id.trim().isEmpty) {
      return null;
    }

    return id;
  }

  String? get _effectiveOrderCode {
    final code = payment?.orderCode ?? orderCode;
    if (code == null || code.trim().isEmpty) {
      return null;
    }

    return code;
  }

  @override
  Widget build(BuildContext context) {
    final color = success ? AppTheme.success : AppTheme.warning;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: color,
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'Thanh toán thành công' : 'Thanh toán thất bại',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    (success
                        ? 'Đơn hàng của bạn đã được thanh toán qua VNPay.'
                        : 'Giao dịch chưa hoàn tất. Bạn có thể thử lại hoặc chọn phương thức khác.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              if (_effectiveOrderCode != null) ...[
                const SizedBox(height: 26),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mã đơn hàng',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _effectiveOrderCode!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  final orderId = _effectiveOrderId;
                  Navigator.of(context).pushReplacementNamed(
                    orderId == null ? AppRoutes.orders : AppRoutes.orderDetail,
                    arguments: orderId == null ? null : {'orderId': orderId},
                  );
                },
                child: const Text('Xem đơn hàng'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
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
