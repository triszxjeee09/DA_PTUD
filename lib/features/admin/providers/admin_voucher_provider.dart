import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../voucher/data/models/voucher_model.dart';
import '../data/models/admin_voucher_request_model.dart';
import '../data/services/admin_voucher_service.dart';

class AdminVoucherProvider extends ChangeNotifier {
  AdminVoucherProvider({AdminVoucherService? adminVoucherService})
    : _adminVoucherService = adminVoucherService ?? AdminVoucherService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminVoucherService _adminVoucherService;

  List<VoucherModel> _vouchers = const [];
  VoucherModel? _selectedVoucher;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String _keyword = '';
  int _page = 0;
  int _size = 20;
  int _totalPages = 1;
  int _totalElements = 0;
  bool _isLast = true;

  List<VoucherModel> get vouchers => _vouchers;
  VoucherModel? get selectedVoucher => _selectedVoucher;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;
  int get page => _page;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get isFirstPage => _page <= 0;
  bool get isLastPage => _isLast || _page >= _totalPages - 1;

  Future<void> loadVouchers({String? keyword, int? page}) async {
    if (keyword != null) {
      _keyword = keyword.trim();
      _page = 0;
    }

    if (page != null) {
      _page = page < 0 ? 0 : page;
    }

    _setLoading(true);

    try {
      final result = await _adminVoucherService.getVouchers(
        keyword: _keyword,
        page: _page,
        size: _size,
      );
      _vouchers = result.content;
      _page = result.page;
      _size = result.size == 0 ? _size : result.size;
      _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
      _totalElements = result.totalElements;
      _isLast = result.last;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> nextPage() {
    if (isLastPage) {
      return Future.value();
    }

    return loadVouchers(page: _page + 1);
  }

  Future<void> previousPage() {
    if (isFirstPage) {
      return Future.value();
    }

    return loadVouchers(page: _page - 1);
  }

  Future<VoucherModel?> loadVoucherDetail(String id) async {
    _setLoadingDetail(true);

    try {
      _selectedVoucher = await _adminVoucherService.getVoucherDetail(id);
      _errorMessage = null;
      return _selectedVoucher;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return null;
    } finally {
      _setLoadingDetail(false);
    }
  }

  Future<bool> createVoucher(AdminVoucherRequestModel request) async {
    _setSaving(true);

    try {
      await _adminVoucherService.createVoucher(request);
      await loadVouchers(page: 0);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> updateVoucher(
    String id,
    AdminVoucherRequestModel request,
  ) async {
    _setSaving(true);

    try {
      await _adminVoucherService.updateVoucher(id, request);
      await loadVouchers(page: _page);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> deleteVoucher(String id) async {
    _setDeleting(true);

    try {
      await _adminVoucherService.deleteVoucher(id);
      await loadVouchers(page: _page);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setDeleting(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setLoadingDetail(bool value) {
    if (_isLoadingDetail == value) {
      return;
    }

    _isLoadingDetail = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    if (_isSaving == value) {
      return;
    }

    _isSaving = value;
    notifyListeners();
  }

  void _setDeleting(bool value) {
    if (_isDeleting == value) {
      return;
    }

    _isDeleting = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
