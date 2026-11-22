import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Hóa đơn điện tử của một đơn hàng (dữ liệu từ `/orders/{id}/invoice`).
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final JsonApi _api = JsonApi();
  Map<String, dynamic>? _invoice;
  String? _error;
  bool _loading = true;

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
      final data = await _api.get('/orders/${widget.orderId}/invoice');
      _invoice = JsonApi.asMap(data);
    } catch (error) {
      _error = JsonApi.message(error);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  num _num(Object? value) => num.tryParse(value?.toString() ?? '') ?? 0;

  String _asText(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) {
    final buffer = StringBuffer()
      ..writeln('HÓA ĐƠN ${invoice['invoiceNumber']}')
      ..writeln('Đơn hàng: ${invoice['orderCode']}')
      ..writeln('Khách hàng: ${invoice['customerName'] ?? ''}');
    for (final item in items) {
      buffer.writeln(
        '- ${item['productName']} x${item['quantity']}: ${CurrencyFormatter.format(_num(item['totalPrice']))}',
      );
    }
    buffer.writeln('Tổng thanh toán: ${CurrencyFormatter.format(_num(invoice['total']))}');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    final items = invoice == null ? <Map<String, dynamic>>[] : JsonApi.asList(invoice['items']);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        actions: [
          if (invoice != null)
            IconButton(
              tooltip: 'Sao chép',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _asText(invoice, items)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép nội dung hóa đơn')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : invoice == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Không tải được hóa đơn'),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text(
                                (invoice['seller'] ?? 'Nhà thuốc An Tâm').toString(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              const SizedBox(height: 2),
                              Text('Số hóa đơn: ${invoice['invoiceNumber']}'),
                            ],
                          ),
                        ),
                        const Divider(height: 28),
                        _line('Mã đơn hàng', '${invoice['orderCode']}'),
                        _line('Chi nhánh', '${invoice['pharmacyName'] ?? '-'}'),
                        _line('Khách hàng', '${invoice['customerName'] ?? '-'}'),
                        _line('Điện thoại', '${invoice['customerPhone'] ?? '-'}'),
                        _line('Địa chỉ giao', '${invoice['shippingAddress'] ?? '-'}'),
                        _line('Thanh toán', '${invoice['paymentMethod'] ?? '-'} (${invoice['paymentStatus'] ?? '-'})'),
                        const Divider(height: 28),
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['productName']}\n${item['quantity']} x ${CurrencyFormatter.format(_num(item['unitPrice']))}',
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(_num(item['totalPrice'])),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 28),
                        _line('Tạm tính', CurrencyFormatter.format(_num(invoice['subtotal']))),
                        _line('Giảm giá', '-${CurrencyFormatter.format(_num(invoice['discount']))}'),
                        _line('Phí vận chuyển', CurrencyFormatter.format(_num(invoice['shippingFee']))),
                        const SizedBox(height: 4),
                        _line('Tổng thanh toán', CurrencyFormatter.format(_num(invoice['total'])), bold: true),
                        if (_num(invoice['pointsEarned']) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Điểm thưởng nhận được: +${_num(invoice['pointsEarned'])}',
                              style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                fontSize: bold ? 17 : 14,
                color: bold ? AppTheme.darkBlue : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
