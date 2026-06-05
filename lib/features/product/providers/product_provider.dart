import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/product_model.dart';
import '../data/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductService? productService})
    : _productService = productService ?? ProductService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final ProductService _productService;

  List<ProductModel> _products = const [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  Future<void> loadProducts({
    String? keyword,
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    bool? requiresPrescription,
    bool? isFeatured,
    bool refresh = false,
  }) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _products = const [];
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = refresh ? 0 : _currentPage;
    if (_products.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _productService.getProducts(
        keyword: keyword,
        categoryId: categoryId,
        brandId: brandId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        requiresPrescription: requiresPrescription,
        isFeatured: isFeatured,
        page: pageToLoad,
      );

      _products = pageToLoad == 0
          ? pageResponse.content
          : [..._products, ...pageResponse.content];
      _currentPage = pageToLoad + 1;
      _hasMore = !pageResponse.last && _currentPage < pageResponse.totalPages;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  Future<void> loadProductDetail(String id) async {
    _setLoading(true);

    try {
      _selectedProduct = await _productService.getProductById(id);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  void clearSelectedProduct() {
    if (_selectedProduct == null) {
      return;
    }

    _selectedProduct = null;
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
