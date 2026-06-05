import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/category_model.dart';
import '../data/services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider({CategoryService? categoryService})
    : _categoryService = categoryService ?? CategoryService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final CategoryService _categoryService;

  List<CategoryModel> _categories = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _setLoading(true);

    try {
      _categories = await _categoryService.getCategories();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
