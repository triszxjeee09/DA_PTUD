import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../brand/data/models/brand_model.dart';
import '../data/models/admin_brand_request_model.dart';
import '../data/services/admin_brand_service.dart';

class AdminBrandProvider extends ChangeNotifier {
  AdminBrandProvider({AdminBrandService? adminBrandService})
    : _adminBrandService = adminBrandService ?? AdminBrandService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminBrandService _adminBrandService;

  List<BrandModel> _brands = const [];
  BrandModel? _selectedBrand;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String _keyword = '';

  List<BrandModel> get brands {
    final keyword = _keyword.toLowerCase().trim();
    if (keyword.isEmpty) {
      return _brands;
    }

    return _brands.where((brand) {
      return brand.name.toLowerCase().contains(keyword) ||
          (brand.country ?? '').toLowerCase().contains(keyword) ||
          (brand.description ?? '').toLowerCase().contains(keyword);
    }).toList();
  }

  List<BrandModel> get allBrands => _brands;
  BrandModel? get selectedBrand => _selectedBrand;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;

  Future<void> loadBrands({String? keyword}) async {
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    _setLoading(true);

    try {
      _brands = await _adminBrandService.getBrands();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  void search(String keyword) {
    _keyword = keyword.trim();
    notifyListeners();
  }

  Future<BrandModel?> loadBrandDetail(String id) async {
    _setLoadingDetail(true);

    try {
      _selectedBrand = await _adminBrandService.getBrandDetail(id);
      _errorMessage = null;
      return _selectedBrand;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return null;
    } finally {
      _setLoadingDetail(false);
    }
  }

  Future<bool> createBrand(AdminBrandRequestModel request) async {
    _setSaving(true);

    try {
      await _adminBrandService.createBrand(request);
      await loadBrands();
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

  Future<bool> updateBrand(String id, AdminBrandRequestModel request) async {
    _setSaving(true);

    try {
      await _adminBrandService.updateBrand(id, request);
      await loadBrands();
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

  Future<bool> deleteBrand(String id) async {
    _setDeleting(true);

    try {
      await _adminBrandService.deleteBrand(id);
      await loadBrands();
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
