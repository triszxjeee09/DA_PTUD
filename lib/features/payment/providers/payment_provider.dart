import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/create_payment_request_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/update_payment_status_request_model.dart';
import '../data/models/vnpay_create_payment_request_model.dart';
import '../data/models/vnpay_create_payment_response_model.dart';
import '../data/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService? paymentService})
    : _paymentService = paymentService ?? PaymentService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final PaymentService _paymentService;

  PaymentModel? _selectedPayment;
  VnPayCreatePaymentResponseModel? _vnPayPayment;
  List<PaymentModel> _payments = const [];
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isCreatingVnPayPayment = false;
  String? _errorMessage;

  PaymentModel? get selectedPayment => _selectedPayment;
  VnPayCreatePaymentResponseModel? get vnPayPayment => _vnPayPayment;
  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  bool get isCreatingVnPayPayment => _isCreatingVnPayPayment;
  String? get errorMessage => _errorMessage;

  Future<bool> createPayment(String orderId, String paymentMethod) async {
    _setProcessing(true);

    try {
      _selectedPayment = await _paymentService.createPayment(
        CreatePaymentRequestModel(
          orderId: orderId,
          paymentMethod: paymentMethod,
        ),
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setProcessing(false);
    }
  }

  Future<bool> createVnPayPayment(String orderId) async {
    _setCreatingVnPayPayment(true);

    try {
      _vnPayPayment = await _paymentService.createVnPayPayment(
        VnPayCreatePaymentRequestModel(orderId: orderId),
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setCreatingVnPayPayment(false);
    }
  }

  Future<bool> updatePaymentStatus(
    String paymentId,
    String paymentStatus, {
    String? transactionCode,
  }) async {
    _setProcessing(true);

    try {
      _selectedPayment = await _paymentService.updatePaymentStatus(
        paymentId,
        UpdatePaymentStatusRequestModel(
          paymentStatus: paymentStatus,
          transactionCode: transactionCode,
        ),
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> loadPaymentByOrderId(String orderId) async {
    _setLoading(true);

    try {
      _selectedPayment = await _paymentService.getPaymentByOrderId(orderId);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyPayments() async {
    _setLoading(true);

    try {
      _payments = await _paymentService.getMyPayments();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    if (_isProcessing == value) {
      return;
    }

    _isProcessing = value;
    notifyListeners();
  }

  void _setCreatingVnPayPayment(bool value) {
    if (_isCreatingVnPayPayment == value) {
      return;
    }

    _isCreatingVnPayPayment = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
