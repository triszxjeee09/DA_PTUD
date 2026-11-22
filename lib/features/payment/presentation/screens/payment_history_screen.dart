import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Lịch sử thanh toán của khách (`/payments/my-payments`).
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final JsonApi _api = JsonApi();
  List<Map<String, dynamic>> _payments = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _payments = JsonApi.asList(await _api.get('/payments/my-payments'));
    } catch (error) {
      _error = JsonApi.message(error);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _date(Object? iso) {
    final d = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    if (d == null) {
      return '';
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _color(String status) {
    switch (status) {
      case 'PAID':
        return AppTheme.success;
      case 'FAILED':
      case 'REFUNDED':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Lịch sử thanh toán')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _payments.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 140),
                  const Icon(
                    Icons.payments_outlined,
                    size: 56,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Center(child: Text(_error ?? 'Chưa có giao dịch thanh toán')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final payment = _payments[index];
                  final status = '${payment['paymentStatus'] ?? ''}';
                  return Card(
                    child: ListTile(
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.orderDetail,
                        arguments: {'orderId': payment['orderId']},
                      ),
                      title: Text(
                        'Đơn ${payment['orderCode'] ?? payment['orderId']}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${payment['paymentMethod'] ?? ''} • ${_date(payment['createdAt'])}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(
                              num.tryParse('${payment['amount']}') ?? 0,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${payment['paymentStatusLabel'] ?? status}',
                            style: TextStyle(
                              color: _color(status),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
