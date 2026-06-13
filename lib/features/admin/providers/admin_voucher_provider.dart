import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/admin_voucher_model.dart';
import '../data/models/admin_voucher_request_model.dart';
import '../data/services/admin_voucher_service.dart';

class AdminVoucherProvider extends ChangeNotifier {
  AdminVoucherProvider({AdminVoucherService? adminVoucherService})
    : _adminVoucherService = adminVoucherService ?? AdminVoucherService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const int _pageSize = 10;

  final AdminVoucherService _adminVoucherService;

  final List<AdminVoucherModel> _vouchers = [];
  AdminVoucherModel? _selectedVoucher;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentKeyword;
  bool? _currentIsActiveFilter;

  List<AdminVoucherModel> get vouchers => List.unmodifiable(_vouchers);
  AdminVoucherModel? get selectedVoucher => _selectedVoucher;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get currentKeyword => _currentKeyword;
  bool? get currentIsActiveFilter => _currentIsActiveFilter;

  Future<void> loadVouchers({
    bool refresh = false,
    String? keyword,
    bool? isActive,
  }) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    final nextKeyword = _normalizeKeyword(keyword);
    final filterChanged =
        nextKeyword != _currentKeyword || isActive != _currentIsActiveFilter;
    final shouldRefresh = refresh || filterChanged;

    if (shouldRefresh) {
      _currentPage = 0;
      _vouchers.clear();
      _hasMore = true;
    } else if (!_hasMore) {
      return;
    }

    _currentKeyword = nextKeyword;
    _currentIsActiveFilter = isActive;

    final pageToLoad = _currentPage;
    final isFirstPage = pageToLoad == 0 && _vouchers.isEmpty;

    if (isFirstPage) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint(
          '[AdminVoucher] Load list page=$pageToLoad '
          'keyword=${_currentKeyword ?? ''} '
          'isActive=${_currentIsActiveFilter ?? 'all'}',
        );
      }

      final pageResponse = await _adminVoucherService.getVouchers(
        page: pageToLoad,
        size: _pageSize,
        keyword: _currentKeyword,
        isActive: _currentIsActiveFilter,
      );

      final existingIds = _vouchers.map((voucher) => voucher.id).toSet();
      final newVouchers = pageResponse.content
          .where((voucher) => !existingIds.contains(voucher.id))
          .toList();

      _vouchers.addAll(newVouchers);
      _currentPage = pageResponse.page + 1;
      _hasMore = !pageResponse.last;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadVoucherDetail(String id) async {
    _isLoadingDetail = true;
    _selectedVoucher = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedVoucher = await _adminVoucherService.getVoucherById(id);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createVoucher(AdminVoucherRequestModel request) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminVoucherService.createVoucher(request);
      if (kDebugMode) {
        debugPrint('[AdminVoucher] Created voucher code=${request.code}');
      }
      await loadVouchers(
        refresh: true,
        keyword: _currentKeyword,
        isActive: _currentIsActiveFilter,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateVoucher(
    String id,
    AdminVoucherRequestModel request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedVoucher = await _adminVoucherService.updateVoucher(
        id,
        request,
      );
      if (kDebugMode) {
        debugPrint('[AdminVoucher] Updated voucher id=$id');
      }

      final index = _vouchers.indexWhere((voucher) => voucher.id == id);
      if (index >= 0) {
        _vouchers[index] = updatedVoucher;
      }
      _selectedVoucher = updatedVoucher;
      await loadVouchers(
        refresh: true,
        keyword: _currentKeyword,
        isActive: _currentIsActiveFilter,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVoucher(String id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminVoucherService.deleteVoucher(id);
      if (kDebugMode) {
        debugPrint('[AdminVoucher] Deleted voucher id=$id');
      }

      _vouchers.removeWhere((voucher) => voucher.id == id);
      if (_selectedVoucher?.id == id) {
        _selectedVoucher = null;
      }
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  void clearSelectedVoucher() {
    if (_selectedVoucher == null) {
      return;
    }

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

  String? _normalizeKeyword(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
