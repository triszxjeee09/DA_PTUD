import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/admin_category_model.dart';
import '../data/models/admin_category_request_model.dart';
import '../data/services/admin_category_service.dart';

class AdminCategoryProvider extends ChangeNotifier {
  AdminCategoryProvider({AdminCategoryService? adminCategoryService})
    : _adminCategoryService = adminCategoryService ?? AdminCategoryService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminCategoryService _adminCategoryService;

  final List<AdminCategoryModel> _categories = [];
  AdminCategoryModel? _selectedCategory;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentKeyword;
  bool? _currentIsActiveFilter;

  List<AdminCategoryModel> get categories => List.unmodifiable(_categories);
  List<AdminCategoryModel> get allCategories => categories;
  AdminCategoryModel? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get isSaving => _isSubmitting;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get currentKeyword => _currentKeyword;
  String get keyword => _currentKeyword ?? '';
  bool? get currentIsActiveFilter => _currentIsActiveFilter;

  Future<void> loadCategories({
    bool refresh = false,
    String? keyword,
    bool? isActive,
  }) async {
    final nextKeyword = _emptyToNull(keyword);
    final filterChanged =
        nextKeyword != _currentKeyword || isActive != _currentIsActiveFilter;
    final shouldRefresh = refresh || filterChanged;

    if (shouldRefresh) {
      _currentPage = 0;
      _categories.clear();
      _hasMore = true;
    } else if (!_hasMore) {
      return;
    }

    _currentKeyword = nextKeyword;
    _currentIsActiveFilter = isActive;

    final loadingMore = !shouldRefresh && _categories.isNotEmpty;
    _setLoadingState(loadingMore: loadingMore, value: true);

    try {
      final response = await _adminCategoryService.getCategories(
        page: _currentPage,
        keyword: _currentKeyword,
        isActive: _currentIsActiveFilter,
      );

      final existingIds = _categories.map((category) => category.id).toSet();
      final newCategories = response.content
          .where((category) => !existingIds.contains(category.id))
          .toList();

      _categories.addAll(newCategories);
      _currentPage = response.page + 1;
      _hasMore = !response.last;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoadingState(loadingMore: loadingMore, value: false);
    }
  }

  Future<void> loadCategoryDetail(String id) async {
    _setLoading(true);

    try {
      _selectedCategory = await _adminCategoryService.getCategoryById(id);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createCategory(AdminCategoryRequestModel request) async {
    _setSubmitting(true);

    try {
      await _adminCategoryService.createCategory(request);
      await loadCategories(
        refresh: true,
        keyword: _currentKeyword,
        isActive: _currentIsActiveFilter,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> updateCategory(
    String id,
    AdminCategoryRequestModel request,
  ) async {
    _setSubmitting(true);

    try {
      await _adminCategoryService.updateCategory(id, request);
      await loadCategories(
        refresh: true,
        keyword: _currentKeyword,
        isActive: _currentIsActiveFilter,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> deleteCategory(String id) async {
    _setDeleting(true);

    try {
      await _adminCategoryService.deleteCategory(id);
      _categories.removeWhere((category) => category.id == id);
      if (_selectedCategory?.id == id) {
        _selectedCategory = null;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setDeleting(false);
    }
  }

  void clearSelectedCategory() {
    if (_selectedCategory == null) {
      return;
    }

    _selectedCategory = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void search(String keyword) {
    loadCategories(refresh: true, keyword: keyword);
  }

  void _setLoadingState({required bool loadingMore, required bool value}) {
    if (loadingMore) {
      _setLoadingMore(value);
    } else {
      _setLoading(value);
    }
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

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) {
      return;
    }

    _isSubmitting = value;
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

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
