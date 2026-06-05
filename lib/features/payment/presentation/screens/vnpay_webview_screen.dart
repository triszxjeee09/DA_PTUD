import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';

class VnPayWebViewScreen extends StatefulWidget {
  const VnPayWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    required this.orderCode,
  });

  final String paymentUrl;
  final String orderId;
  final String orderCode;

  @override
  State<VnPayWebViewScreen> createState() => _VnPayWebViewScreenState();
}

class _VnPayWebViewScreenState extends State<VnPayWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _handledReturnUrl = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final paymentUri = Uri.tryParse(widget.paymentUrl.trim());
    if (paymentUri == null || !paymentUri.hasScheme) {
      _isLoading = false;
      _hasError = true;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) {
              return;
            }

            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            _handleReturnUrl(url);
          },
          onPageFinished: (url) {
            if (!mounted) {
              return;
            }

            setState(() {
              _isLoading = false;
            });
            _handleReturnUrl(url);
          },
          onWebResourceError: (_) {
            if (!mounted || _handledReturnUrl) {
              return;
            }

            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
          onNavigationRequest: (request) {
            _handleReturnUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(paymentUri);
  }

  void _handleReturnUrl(String url) {
    if (_handledReturnUrl || !url.contains('/api/v1/payments/vnpay-return')) {
      return;
    }

    _handledReturnUrl = true;
    final uri = Uri.tryParse(url);
    final queryParams = uri?.queryParameters ?? const <String, String>{};
    final success =
        queryParams['vnp_ResponseCode'] == '00' &&
        queryParams['vnp_TransactionStatus'] == '00';

    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paymentResult,
        arguments: {
          'success': success,
          'orderId': widget.orderId,
          'orderCode': widget.orderCode,
          'message': success
              ? 'Thanh toán VNPay thành công'
              : 'Thanh toán VNPay thất bại hoặc đã bị hủy',
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          if (_hasError || controller == null)
            const _PaymentPageError()
          else
            WebViewWidget(controller: controller),
          if (_isLoading && !_hasError)
            const LinearProgressIndicator(
              color: AppTheme.primaryBlue,
              backgroundColor: AppTheme.lightBlue,
            ),
        ],
      ),
    );
  }
}

class _PaymentPageError extends StatelessWidget {
  const _PaymentPageError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Không thể tải trang thanh toán',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
