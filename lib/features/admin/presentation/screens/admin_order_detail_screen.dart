import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Chi tiết đơn hàng cho quản trị: thông tin, sản phẩm, lịch sử, đổi trạng thái, hoàn tiền, hóa đơn.
class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  static const Map<String, String> _statuses = {
    'CONFIRMED': 'Đã xác nhận',
    'PREPARING': 'Đang chuẩn bị',
    'SHIPPING': 'Đang giao',
    'DELIVERED': 'Đã giao',
    'CANCELLED': 'Đã hủy',
  };

  final JsonApi _api = JsonApi();
  Map<String, dynamic>? _order;
  String? _error;
  bool _loading = true;
  bool _busy = false;

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
      _order = JsonApi.asMap(await _api.get('/orders/admin/${widget.orderId}'));
    } catch (error) {
      _error = JsonApi.message(error);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  num _num(Object? value) => num.tryParse('${value ?? ''}') ?? 0;

  Future<void> _run(Future<dynamic> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
      await _load();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(JsonApi.message(error))));
    }
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus() async {
    final status = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cập nhật trạng thái', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            for (final entry in _statuses.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.of(sheetContext).pop(entry.key),
              ),
          ],
        ),
      ),
    );
    if (status == null) {
      return;
    }
    await _run(
      () => _api.put('/orders/admin/${widget.orderId}/status', body: {'status': status}),
      'Đã cập nhật trạng thái',
    );
  }

  Future<void> _refund() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hoàn tiền đơn hàng'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Lý do hoàn tiền'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Hoàn tiền'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) {
      return;
    }
    await _run(
      () => _api.post('/orders/admin/${widget.orderId}/refund', body: {'reason': reason}),
      'Đã hoàn tiền đơn hàng',
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final items = order == null ? <Map<String, dynamic>>[] : JsonApi.asList(order['items']);
    final history = order == null ? <Map<String, dynamic>>[] : JsonApi.asList(order['statusHistories']);
    final canRefund = order != null &&
        order['paymentStatus'] != 'REFUNDED' &&
        (order['paymentStatus'] == 'PAID' || order['orderStatus'] == 'CANCELLED');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: Text(order == null ? 'Chi tiết đơn hàng' : '${order['orderCode']}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Không tải được đơn hàng'),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line('Trạng thái', '${order['orderStatusLabel'] ?? order['orderStatus']}'),
                        _line('Thanh toán', '${order['paymentMethod']} • ${order['paymentStatus']}'),
                        _line('Khách hàng', '${order['customerName'] ?? order['receiverName'] ?? ''}'),
                        _line('Người nhận', '${order['receiverName'] ?? ''} • ${order['receiverPhone'] ?? ''}'),
                        _line('Địa chỉ', '${order['shippingAddress'] ?? ''}'),
                        _line('Chi nhánh', '${order['pharmacyName'] ?? '-'}'),
                        if ((order['note'] ?? '').toString().isNotEmpty) _line('Ghi chú', '${order['note']}'),
                        if (order['refundReason'] != null) _line('Hoàn tiền', '${order['refundReason']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text('${item['productName']} × ${item['quantity']}')),
                                Text(CurrencyFormatter.format(_num(item['totalPrice']))),
                              ],
                            ),
                          ),
                        const Divider(),
                        _line('Giảm giá', '-${CurrencyFormatter.format(_num(order['discountAmount']))}'),
                        _line('Thành tiền', CurrencyFormatter.format(_num(order['finalAmount']))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lịch sử xử lý', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        for (final h in history.reversed)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history, size: 20),
                            title: Text('${h['statusLabel'] ?? h['status']}'),
                            subtitle: Text(
                              '${h['changedByName'] ?? ''} ${h['note'] ?? ''}'.trim(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : _changeStatus,
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Đổi trạng thái'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.invoice,
                        arguments: {'orderId': widget.orderId},
                      ),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Hóa đơn'),
                    ),
                    if (canRefund)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _refund,
                        icon: const Icon(Icons.currency_exchange),
                        label: const Text('Hoàn tiền'),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
