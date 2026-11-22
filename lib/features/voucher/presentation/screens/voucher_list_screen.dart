import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../providers/voucher_provider.dart';

/// Danh sách khuyến mãi / voucher đang áp dụng (bao gồm voucher đổi từ điểm thưởng).
class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VoucherProvider>().loadVouchers();
      }
    });
  }

  String _discountText(double value, String type, double? max) {
    if (type.toUpperCase().contains('PERCENT')) {
      final base = 'Giảm ${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}%';
      return max == null ? base : '$base (tối đa ${CurrencyFormatter.format(max)})';
    }
    return 'Giảm ${CurrencyFormatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoucherProvider>();
    final vouchers = provider.vouchers;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        title: const Text('Khuyến mãi'),
        actions: [
          IconButton(
            tooltip: 'Điểm thưởng',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.loyalty),
            icon: const Icon(Icons.card_giftcard),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadVouchers,
        child: provider.isLoading && vouchers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : vouchers.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 140),
                  const Icon(Icons.local_offer_outlined, size: 56, color: AppTheme.primaryBlue),
                  const SizedBox(height: 12),
                  Center(child: Text(provider.errorMessage ?? 'Hiện chưa có khuyến mãi')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vouchers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final voucher = vouchers[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(voucher.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            _discountText(voucher.discountValue, voucher.discountType, voucher.maxDiscountAmount),
                            style: const TextStyle(color: AppTheme.darkBlue, fontWeight: FontWeight.w800),
                          ),
                          if (voucher.minOrderAmount > 0)
                            Text(
                              'Đơn tối thiểu ${CurrencyFormatter.format(voucher.minOrderAmount)}',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          if ((voucher.description ?? '').isNotEmpty) Text(voucher.description!),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(voucher.code, style: const TextStyle(fontWeight: FontWeight.w900)),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: voucher.code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã sao chép mã')),
                                  );
                                },
                                child: const Text('Sao chép'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
