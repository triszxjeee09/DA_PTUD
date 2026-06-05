import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({
    super.key,
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    this.orderCode,
  });

  final String orderId;
  final String paymentMethod;
  final double amount;
  final String? orderCode;

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_started) {
        _started = true;
        _processPayment();
      }
    });
  }

  Future<void> _processPayment() async {
    final paymentProvider = context.read<PaymentProvider>();

    if (widget.paymentMethod == 'VNPAY') {
      await _processVnPayPayment(paymentProvider);
      return;
    }

    final created = await paymentProvider.createPayment(
      widget.orderId,
      widget.paymentMethod,
    );

    if (!mounted) {
      return;
    }

    if (!created) {
      _openResult(
        success: false,
        message: paymentProvider.errorMessage ?? 'Không thể tạo thanh toán',
      );
      return;
    }

    final payment = paymentProvider.selectedPayment;
    if (payment == null) {
      _openResult(
        success: false,
        message: 'Không tìm thấy thông tin thanh toán',
      );
      return;
    }

    if (widget.paymentMethod == 'COD') {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) {
        _openResult(success: true, payment: payment);
      }
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    final transactionCode =
        'TXN${DateTime.now().millisecondsSinceEpoch.toString()}';
    final updated = await paymentProvider.updatePaymentStatus(
      payment.id,
      'SUCCESS',
      transactionCode: transactionCode,
    );

    if (!mounted) {
      return;
    }

    _openResult(
      success: updated,
      payment: paymentProvider.selectedPayment ?? payment,
      transactionCode: transactionCode,
      message: updated
          ? null
          : paymentProvider.errorMessage ?? 'Thanh toán không thành công',
    );
  }

  Future<void> _processVnPayPayment(PaymentProvider paymentProvider) async {
    final created = await paymentProvider.createVnPayPayment(widget.orderId);

    if (!mounted) {
      return;
    }

    if (!created) {
      _openResult(
        success: false,
        message:
            paymentProvider.errorMessage ?? 'Không thể tạo thanh toán VNPay',
      );
      return;
    }

    final vnPayPayment = paymentProvider.vnPayPayment;
    if (vnPayPayment == null || vnPayPayment.paymentUrl.trim().isEmpty) {
      _openResult(
        success: false,
        message: 'Không tìm thấy đường dẫn thanh toán VNPay',
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.paymentVnPay,
      arguments: {
        'paymentUrl': vnPayPayment.paymentUrl,
        'orderId': vnPayPayment.orderId.isNotEmpty
            ? vnPayPayment.orderId
            : widget.orderId,
        'orderCode': vnPayPayment.orderCode.isNotEmpty
            ? vnPayPayment.orderCode
            : widget.orderCode,
      },
    );
  }

  void _openResult({
    required bool success,
    PaymentModel? payment,
    String? transactionCode,
    String? message,
  }) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.paymentResult,
      arguments: {
        'success': success,
        'payment': payment,
        'orderId': widget.orderId,
        'orderCode': widget.orderCode,
        'paymentMethod': widget.paymentMethod,
        'amount': widget.amount,
        'transactionCode': transactionCode ?? payment?.transactionCode,
        'message': message,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 108,
                height: 108,
                decoration: const BoxDecoration(
                  color: AppTheme.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.primaryBlue,
                  size: 58,
                ),
              ),
              const SizedBox(height: 26),
              const CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 28),
              const Text(
                'Đang xử lý thanh toán',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng không tắt ứng dụng trong quá trình thanh toán',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _PaymentInfoCard(
                orderCode: widget.orderCode,
                amount: widget.amount,
                paymentMethod: widget.paymentMethod,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard({
    required this.orderCode,
    required this.amount,
    required this.paymentMethod,
  });

  final String? orderCode;
  final double amount;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InfoRow(label: 'Mã đơn hàng', value: orderCode ?? 'Đang cập nhật'),
            const Divider(height: 24),
            _InfoRow(label: 'Số tiền', value: CurrencyFormatter.format(amount)),
            const Divider(height: 24),
            _InfoRow(
              label: 'Phương thức',
              value: _paymentMethodLabel(paymentMethod),
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
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
