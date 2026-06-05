import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/inventory_model.dart';
import '../data/services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider({InventoryService? inventoryService})
    : _inventoryService = inventoryService ?? InventoryService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const int _pageSize = 10;

  final InventoryService _inventoryService;

  List<InventoryModel> _productInventories = const [];
  List<InventoryModel> _pharmacyInventories = const [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentPharmacyId;

  List<InventoryModel> get productInventories => _productInventories;
  List<InventoryModel> get pharmacyInventories => _pharmacyInventories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  Future<void> loadInventoryByProduct(String productId) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      _errorMessage = 'Không tìm thấy sản phẩm';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      _productInventories = await _inventoryService.getInventoryByProduct(
        normalizedProductId,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadInventoryByPharmacy({
    required String pharmacyId,
    bool refresh = false,
  }) async {
    final normalizedPharmacyId = pharmacyId.trim();
    if (normalizedPharmacyId.isEmpty) {
      _errorMessage = 'Không tìm thấy nhà thuốc';
      notifyListeners();
      return;
    }

    final pharmacyChanged = _currentPharmacyId != normalizedPharmacyId;

    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh || pharmacyChanged) {
      _pharmacyInventories = const [];
      _currentPage = 0;
      _hasMore = true;
      _currentPharmacyId = normalizedPharmacyId;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = _currentPage;
    if (_pharmacyInventories.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _inventoryService.getInventoryByPharmacy(
        pharmacyId: normalizedPharmacyId,
        page: pageToLoad,
        size: _pageSize,
      );

      _pharmacyInventories = pageToLoad == 0
          ? pageResponse.content
          : [..._pharmacyInventories, ...pageResponse.content];
      _currentPage = pageToLoad + 1;
      _hasMore = !pageResponse.last && _currentPage < pageResponse.totalPages;
      _currentPharmacyId = normalizedPharmacyId;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  void clearProductInventories() {
    if (_productInventories.isEmpty) {
      return;
    }

    _productInventories = const [];
    notifyListeners();
  }

  void clearPharmacyInventories() {
    if (_pharmacyInventories.isEmpty &&
        _currentPage == 0 &&
        _hasMore &&
        _currentPharmacyId == null) {
      return;
    }

    _pharmacyInventories = const [];
    _currentPage = 0;
    _hasMore = true;
    _currentPharmacyId = null;
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

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) {
      return;
    }

    _isLoadingMore = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
