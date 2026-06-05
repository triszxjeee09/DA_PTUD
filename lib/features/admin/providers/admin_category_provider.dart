import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../category/data/models/category_model.dart';
import '../data/models/admin_category_request_model.dart';
import '../data/services/admin_category_service.dart';

class AdminCategoryProvider extends ChangeNotifier {
  AdminCategoryProvider({AdminCategoryService? adminCategoryService})
    : _adminCategoryService = adminCategoryService ?? AdminCategoryService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminCategoryService _adminCategoryService;

  List<CategoryModel> _categories = const [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String _keyword = '';

  List<CategoryModel> get categories {
    final keyword = _keyword.toLowerCase().trim();
    if (keyword.isEmpty) {
      return _categories;
    }

    return _categories.where((category) {
      return category.name.toLowerCase().contains(keyword) ||
          category.slug.toLowerCase().contains(keyword) ||
          (category.description ?? '').toLowerCase().contains(keyword);
    }).toList();
  }

  List<CategoryModel> get allCategories => _categories;
  CategoryModel? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;

  Future<void> loadCategories({String? keyword}) async {
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    _setLoading(true);

    try {
      _categories = await _adminCategoryService.getCategories();
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

  Future<CategoryModel?> loadCategoryDetail(String id) async {
    _setLoadingDetail(true);

    try {
      _selectedCategory = await _adminCategoryService.getCategoryDetail(id);
      _errorMessage = null;
      return _selectedCategory;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return null;
    } finally {
      _setLoadingDetail(false);
    }
  }

  Future<bool> createCategory(AdminCategoryRequestModel request) async {
    _setSaving(true);

    try {
      await _adminCategoryService.createCategory(request);
      await loadCategories();
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

  Future<bool> updateCategory(
    String id,
    AdminCategoryRequestModel request,
  ) async {
    _setSaving(true);

    try {
      await _adminCategoryService.updateCategory(id, request);
      await loadCategories();
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

  Future<bool> deleteCategory(String id) async {
    _setDeleting(true);

    try {
      await _adminCategoryService.deleteCategory(id);
      await loadCategories();
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
