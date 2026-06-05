import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/apply_voucher_request_model.dart';
import '../data/models/apply_voucher_response_model.dart';
import '../data/models/voucher_model.dart';
import '../data/services/voucher_service.dart';

class VoucherProvider extends ChangeNotifier {
  VoucherProvider({VoucherService? voucherService})
    : _voucherService = voucherService ?? VoucherService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final VoucherService _voucherService;

  List<VoucherModel> _vouchers = const [];
  VoucherModel? _selectedVoucher;
  ApplyVoucherResponseModel? _appliedVoucher;
  bool _isLoading = false;
  bool _isApplying = false;
  String? _errorMessage;

  List<VoucherModel> get vouchers => _vouchers;
  VoucherModel? get selectedVoucher => _selectedVoucher;
  ApplyVoucherResponseModel? get appliedVoucher => _appliedVoucher;
  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  String? get errorMessage => _errorMessage;

  Future<void> loadVouchers() async {
    _setLoading(true);

    try {
      _vouchers = await _voucherService.getActiveVouchers();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> applyVoucher(String code, double orderAmount) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      _errorMessage = 'Vui lòng nhập mã giảm giá';
      notifyListeners();
      return false;
    }

    _setApplying(true);

    try {
      _appliedVoucher = await _voucherService.applyVoucher(
        ApplyVoucherRequestModel(
          code: normalizedCode,
          orderAmount: orderAmount,
        ),
      );
      _selectedVoucher = _findVoucherByCode(_appliedVoucher!.code);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setApplying(false);
    }
  }

  void selectVoucher(VoucherModel voucher) {
    _selectedVoucher = voucher;
    notifyListeners();
  }

  void clearAppliedVoucher() {
    if (_appliedVoucher == null && _selectedVoucher == null) {
      return;
    }

    _appliedVoucher = null;
    _selectedVoucher = null;
    notifyListeners();
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

  void _setApplying(bool value) {
    if (_isApplying == value) {
      return;
    }

    _isApplying = value;
    notifyListeners();
  }

  VoucherModel? _findVoucherByCode(String code) {
    final normalizedCode = code.trim().toLowerCase();
    for (final voucher in _vouchers) {
      if (voucher.code.trim().toLowerCase() == normalizedCode) {
        return voucher;
      }
    }

    return null;
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
