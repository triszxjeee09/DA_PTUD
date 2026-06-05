import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../inventory/data/models/inventory_model.dart';
import '../data/models/admin_inventory_request_model.dart';
import '../data/services/admin_inventory_service.dart';

class AdminInventoryProvider extends ChangeNotifier {
  AdminInventoryProvider({AdminInventoryService? adminInventoryService})
    : _adminInventoryService = adminInventoryService ?? AdminInventoryService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminInventoryService _adminInventoryService;

  List<InventoryModel> _inventories = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String? _pharmacyId;
  String? _productId;
  String _keyword = '';

  List<InventoryModel> get inventories => _inventories;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String? get pharmacyId => _pharmacyId;
  String? get productId => _productId;
  String get keyword => _keyword;

  Future<void> loadInventories({
    String? pharmacyId,
    String? productId,
    String? keyword,
  }) async {
    if (pharmacyId != null) {
      _pharmacyId = _emptyToNull(pharmacyId);
    }
    if (productId != null) {
      _productId = _emptyToNull(productId);
    }
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    _setLoading(true);

    try {
      _inventories = await _adminInventoryService.getInventories(
        pharmacyId: _pharmacyId,
        productId: _productId,
        keyword: _keyword,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveInventory(AdminInventoryRequestModel request) async {
    _setSaving(true);

    try {
      await _adminInventoryService.saveInventory(request);
      await loadInventories();
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

  Future<bool> updateQuantity(String id, int quantity) async {
    _setSaving(true);

    try {
      await _adminInventoryService.updateQuantity(id, quantity);
      await loadInventories();
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

  Future<bool> deleteInventory(String id) async {
    _setDeleting(true);

    try {
      await _adminInventoryService.deleteInventory(id);
      await loadInventories();
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

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
