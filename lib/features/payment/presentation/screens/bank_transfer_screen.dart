import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Hướng dẫn chuyển khoản ngân hàng kèm mã QR (VietQR) cho đơn hàng.
class BankTransferScreen extends StatefulWidget {
  const BankTransferScreen({super.key, required this.orderId, required this.orderCode});

  final String orderId;
  final String orderCode;

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final JsonApi _api = JsonApi();
  Map<String, dynamic>? _info;
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
      _info = JsonApi.asMap(await _api.get('/payments/bank-qr', query: {'orderId': widget.orderId}));
    } catch (error) {
      _error = JsonApi.message(error);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(
            tooltip: 'Sao chép',
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(label.toLowerCase(), value),
            icon: const Icon(Icons.copy, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Chuyển khoản ngân hàng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : info == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Không tải được thông tin chuyển khoản'),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Đặt hàng thành công! Vui lòng chuyển khoản theo thông tin dưới đây.',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            info['qrUrl'].toString(),
                            height: 240,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) => progress == null
                                ? child
                                : const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 120,
                              child: Center(child: Text('Không tải được mã QR, vui lòng chuyển khoản thủ công')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _row('Ngân hàng', '${info['bankName']}'),
                        _row('Số tài khoản', '${info['accountNo']}'),
                        _row('Chủ tài khoản', '${info['accountName']}'),
                        _row('Số tiền', '${info['amount']}'),
                        _row('Nội dung', '${info['transferContent']}'),
                        const SizedBox(height: 4),
                        Text(
                          'Số tiền: ${CurrencyFormatter.format((num.tryParse('${info['amount']}') ?? 0))}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.darkBlue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nhà thuốc sẽ xác nhận thanh toán sau khi nhận được tiền. '
                  'Hãy ghi đúng nội dung chuyển khoản để đơn được xử lý nhanh.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    AppRoutes.orderDetail,
                    arguments: {'orderId': widget.orderId},
                  ),
                  child: const Text('Xem đơn hàng'),
                ),
              ],
            ),
    );
  }
}
