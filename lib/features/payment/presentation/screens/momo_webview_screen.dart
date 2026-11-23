import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';

/// Bắt đầu thanh toán MoMo cho một đơn: gọi backend tạo giao dịch rồi mở trang thanh toán.
class MomoPayment {
  const MomoPayment._();

  /// Trả về thông báo lỗi nếu không bắt đầu được, `null` nếu đã chuyển sang màn hình thanh toán.
  static Future<String?> start(
    BuildContext context, {
    required String orderId,
    required String orderCode,
    bool replace = false,
  }) async {
    final navigator = Navigator.of(context);
    try {
      final data = JsonApi.asMap(
        await JsonApi().post('/payments/momo/create-payment', body: {'orderId': orderId}),
      );
      final payUrl = data['payUrl']?.toString() ?? '';
      if (payUrl.isEmpty) {
        return 'MoMo không trả về đường dẫn thanh toán';
      }
      final arguments = {
        'payUrl': payUrl,
        'deeplink': data['deeplink']?.toString(),
        'orderId': orderId,
        'orderCode': orderCode,
        'sandbox': data['sandbox'] == true,
      };
      if (replace) {
        navigator.pushReplacementNamed(AppRoutes.paymentMomo, arguments: arguments);
      } else {
        navigator.pushNamed(AppRoutes.paymentMomo, arguments: arguments);
      }
      return null;
    } catch (error) {
      return JsonApi.message(error);
    }
  }
}

/// Trang thanh toán MoMo (WebView). Sau khi thanh toán, backend hỏi MoMo để xác nhận kết quả.
class MomoWebViewScreen extends StatefulWidget {
  const MomoWebViewScreen({
    super.key,
    required this.payUrl,
    required this.orderId,
    required this.orderCode,
    this.deeplink,
    this.sandbox = false,
  });

  final String payUrl;
  final String? deeplink;
  final String orderId;
  final String orderCode;
  final bool sandbox;

  @override
  State<MomoWebViewScreen> createState() => _MomoWebViewScreenState();
}

class _MomoWebViewScreenState extends State<MomoWebViewScreen> {
  static const String _returnPath = '/payments/momo/return';

  final JsonApi _api = JsonApi();
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.payUrl.trim());
    if (uri == null || !uri.hasScheme) {
      _isLoading = false;
      _hasError = true;
      return;
    }
    if (kIsWeb) {
      // WebView không chạy trên Flutter Web: mở trang thanh toán ở tab mới.
      _isLoading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains(_returnPath)) {
              _verify();
              return NavigationDecision.prevent;
            }
            final scheme = Uri.tryParse(url)?.scheme ?? '';
            if (scheme != 'http' && scheme != 'https' && scheme != 'about') {
              _openExternal(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showMessage('Không mở được ứng dụng MoMo. Hãy cài MoMo hoặc quét mã trên trang.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Không mở được ứng dụng MoMo. Hãy cài MoMo hoặc quét mã trên trang.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    if (_verifying) {
      return;
    }
    setState(() => _verifying = true);
    try {
      final data = JsonApi.asMap(
        await _api.post('/payments/momo/verify', body: {'orderId': widget.orderId}),
      );
      if (!mounted) {
        return;
      }
      final status = data['status']?.toString();
      if (status == 'PENDING') {
        setState(() => _verifying = false);
        _showMessage('MoMo chưa ghi nhận thanh toán. Hãy hoàn tất trên MoMo rồi bấm kiểm tra lại.');
        return;
      }
      final success = status == 'PAID';
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paymentResult,
        arguments: {
          'success': success,
          'orderId': widget.orderId,
          'orderCode': widget.orderCode,
          'message': success
              ? 'Thanh toán MoMo thành công'
              : (data['message']?.toString() ?? 'Thanh toán MoMo thất bại hoặc đã bị hủy'),
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() => _verifying = false);
        _showMessage(JsonApi.message(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final deeplink = widget.deeplink;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thanh toán MoMo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          if (widget.sandbox)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF4E5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: const Text(
                'Môi trường thử nghiệm (sandbox): không trừ tiền thật. '
                'Dùng ứng dụng MoMo test hoặc thông tin thử trên trang thanh toán.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                if (kIsWeb && !_hasError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 56,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Thanh toán đơn ${widget.orderCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Trang thanh toán MoMo sẽ mở ở tab mới. Sau khi thanh toán xong, '
                            'quay lại đây và bấm "Tôi đã thanh toán".',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _openExternal(widget.payUrl),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Mở trang thanh toán MoMo'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_hasError || controller == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không thể tải trang thanh toán MoMo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  )
                else
                  WebViewWidget(controller: controller),
                if (_isLoading && !_hasError)
                  const LinearProgressIndicator(
                    color: AppTheme.primaryBlue,
                    backgroundColor: AppTheme.lightBlue,
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (deeplink != null && deeplink.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openExternal(deeplink),
                        child: const Text('Mở ứng dụng MoMo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _verifying ? null : _verify,
                      child: Text(_verifying ? 'Đang kiểm tra...' : 'Tôi đã thanh toán'),
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
}
