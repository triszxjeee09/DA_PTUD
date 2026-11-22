import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Điểm thưởng và lịch sử mua hàng của một khách (dành cho Admin).
class AdminUserLoyaltyCard extends StatefulWidget {
  const AdminUserLoyaltyCard({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserLoyaltyCard> createState() => _AdminUserLoyaltyCardState();
}

class _AdminUserLoyaltyCardState extends State<AdminUserLoyaltyCard> {
  final JsonApi _api = JsonApi();
  Map<String, dynamic>? _summary;
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
      _summary = JsonApi.asMap(await _api.get('/admin/users/${widget.userId}/points'));
    } catch (error) {
      _error = JsonApi.message(error);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _adjust() async {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Điều chỉnh điểm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'Số điểm (+ cộng, - trừ)'),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Lý do'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Lưu')),
        ],
      ),
    );
    final delta = int.tryParse(pointsController.text.trim());
    final reason = reasonController.text.trim();
    pointsController.dispose();
    reasonController.dispose();
    if (ok != true) {
      return;
    }
    if (delta == null || delta == 0 || reason.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Nhập số điểm khác 0 và lý do')));
      return;
    }
    try {
      _summary = JsonApi.asMap(
        await _api.post('/admin/users/${widget.userId}/points', body: {'delta': delta, 'reason': reason}),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật điểm')));
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(JsonApi.message(error))));
    }
  }

  Future<void> _showOrders() async {
    List<Map<String, dynamic>> orders = const [];
    String? error;
    try {
      final data = JsonApi.asMap(await _api.get('/admin/users/${widget.userId}/orders', query: {'size': 50}));
      orders = JsonApi.asList(data['content']);
    } catch (e) {
      error = JsonApi.message(e);
    }
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.65,
        child: orders.isEmpty
            ? Center(child: Text(error ?? 'Khách chưa có đơn hàng'))
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text('${order['orderCode']}'),
                    subtitle: Text('${order['orderStatusLabel'] ?? order['orderStatus']}'),
                    trailing: Text(
                      CurrencyFormatter.format(num.tryParse('${order['finalAmount']}') ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminOrderDetail,
                        arguments: {'orderId': order['id']},
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Điểm thưởng & mua hàng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator()
            else if (summary == null)
              Text(_error ?? 'Không tải được dữ liệu', style: const TextStyle(color: AppTheme.error))
            else
              Text(
                '${summary['points']} điểm • hạng ${summary['tierLabel']} • tích lũy ${summary['lifetimePoints']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: summary == null ? null : _adjust,
                  icon: const Icon(Icons.tune),
                  label: const Text('Cộng/trừ điểm'),
                ),
                OutlinedButton.icon(
                  onPressed: _showOrders,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Lịch sử mua hàng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
