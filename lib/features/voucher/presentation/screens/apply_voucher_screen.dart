import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../data/models/apply_voucher_response_model.dart';
import '../../data/models/voucher_model.dart';
import '../../providers/voucher_provider.dart';

class ApplyVoucherScreen extends StatefulWidget {
  const ApplyVoucherScreen({super.key, required this.orderAmount});

  final double orderAmount;

  @override
  State<ApplyVoucherScreen> createState() => _ApplyVoucherScreenState();
}

class _ApplyVoucherScreenState extends State<ApplyVoucherScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VoucherProvider>().loadVouchers();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyCode([String? code]) async {
    final voucherCode = (code ?? _codeController.text).trim();
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();

    if (voucherCode.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã giảm giá')),
      );
      return;
    }

    final provider = context.read<VoucherProvider>();
    final success = await provider.applyVoucher(
      voucherCode,
      widget.orderAmount,
    );

    if (!mounted) {
      return;
    }

    if (success && provider.appliedVoucher != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Áp dụng voucher thành công')),
      );
      Navigator.of(
        context,
      ).pop<ApplyVoucherResponseModel>(provider.appliedVoucher);
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Không thể áp dụng voucher'),
      ),
    );
  }

  Future<void> _selectVoucher(VoucherModel voucher) async {
    _codeController.text = voucher.code;
    context.read<VoucherProvider>().selectVoucher(voucher);
    await _applyCode(voucher.code);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoucherProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Mã giảm giá')),
      body: RefreshIndicator(
        onRefresh: context.read<VoucherProvider>().loadVouchers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _ApplyCodeCard(
              controller: _codeController,
              orderAmount: widget.orderAmount,
              isApplying: provider.isApplying,
              onApply: () => _applyCode(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Voucher khả dụng',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            if (provider.isLoading && provider.vouchers.isEmpty)
              const _LoadingCard()
            else if (provider.vouchers.isEmpty)
              const _EmptyVoucherView()
            else
              for (final voucher in provider.vouchers) ...[
                _VoucherCard(
                  voucher: voucher,
                  isSelected:
                      provider.selectedVoucher?.code.toLowerCase() ==
                      voucher.code.toLowerCase(),
                  isApplying: provider.isApplying,
                  onSelect: () => _selectVoucher(voucher),
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _ApplyCodeCard extends StatelessWidget {
  const _ApplyCodeCard({
    required this.controller,
    required this.orderAmount,
    required this.isApplying,
    required this.onApply,
  });

  final TextEditingController controller;
  final double orderAmount;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tạm tính: ${CurrencyFormatter.format(orderAmount)}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Nhập mã giảm giá',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              onSubmitted: (_) => onApply(),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Áp dụng',
              onPressed: onApply,
              isLoading: isApplying,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.isSelected,
    required this.isApplying,
    required this.onSelect,
  });

  final VoucherModel voucher;
  final bool isSelected;
  final bool isApplying;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.primaryBlue
        : const Color(0xFFE5E7EB);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _CodePill(code: voucher.code),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              voucher.name.isEmpty ? 'Chương trình ưu đãi' : voucher.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (voucher.description != null &&
                voucher.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                voucher.description!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _VoucherInfoRow(
              icon: Icons.savings_outlined,
              label: 'Giá trị giảm',
              value: _discountText(voucher),
              valueColor: AppTheme.primaryBlue,
            ),
            _VoucherInfoRow(
              icon: Icons.shopping_bag_outlined,
              label: 'Đơn tối thiểu',
              value: CurrencyFormatter.format(voucher.minOrderAmount),
            ),
            _VoucherInfoRow(
              icon: Icons.event_available_outlined,
              label: 'Ngày hết hạn',
              value: voucher.endDate == null
                  ? 'Không giới hạn'
                  : DateFormatter.formatDate(voucher.endDate!),
            ),
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: isSelected ? 'Đã chọn' : 'Chọn',
              onPressed: isApplying ? null : onSelect,
              isLoading: isApplying && isSelected,
              icon: isSelected ? Icons.check : Icons.add_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  static String _discountText(VoucherModel voucher) {
    final type = voucher.discountType.toUpperCase();
    final label = voucher.discountTypeLabel?.trim();
    if (type == 'PERCENT' || type == 'PERCENTAGE') {
      final maxDiscount = voucher.maxDiscountAmount;
      final suffix = maxDiscount == null || maxDiscount <= 0
          ? ''
          : ', tối đa ${CurrencyFormatter.format(maxDiscount)}';
      return 'Giảm ${voucher.discountValue.toStringAsFixed(0)}%$suffix';
    }

    if (label != null && label.isNotEmpty && type != 'FIXED_AMOUNT') {
      return '$label ${CurrencyFormatter.format(voucher.discountValue)}';
    }

    return 'Giảm ${CurrencyFormatter.format(voucher.discountValue)}';
  }
}

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: AppTheme.darkBlue,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _VoucherInfoRow extends StatelessWidget {
  const _VoucherInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 10),
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
              style: TextStyle(
                color: valueColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EmptyVoucherView extends StatelessWidget {
  const _EmptyVoucherView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              color: AppTheme.primaryBlue,
              size: 56,
            ),
            SizedBox(height: 12),
            Text(
              'Hiện chưa có voucher khả dụng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
