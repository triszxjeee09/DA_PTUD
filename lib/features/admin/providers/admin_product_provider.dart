import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/admin_product_request_model.dart';
import '../data/services/admin_product_service.dart';
import '../../product/data/models/product_model.dart';

class AdminProductProvider extends ChangeNotifier {
  AdminProductProvider({AdminProductService? adminProductService})
    : _adminProductService = adminProductService ?? AdminProductService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminProductService _adminProductService;

  List<ProductModel> _products = const [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isSaving = false;
  bool _isUploadingImages = false;
  bool _isUpdatingImage = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String _keyword = '';

  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isSaving => _isSaving;
  bool get isUploadingImages => _isUploadingImages;
  bool get isUpdatingImage => _isUpdatingImage;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;

  Future<void> loadProducts({String? keyword}) async {
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    _setLoading(true);

    try {
      final page = await _adminProductService.getProducts(keyword: _keyword);
      _products = page.content;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<ProductModel?> loadProductDetail(String id) async {
    _setLoadingDetail(true);

    try {
      _selectedProduct = await _adminProductService.getProductDetail(id);
      _errorMessage = null;
      return _selectedProduct;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return null;
    } finally {
      _setLoadingDetail(false);
    }
  }

  Future<bool> createProduct(AdminProductRequestModel request) async {
    _setSaving(true);

    try {
      final product = await _adminProductService.createProduct(request);
      _selectedProduct = product;
      _products = [product, ..._products];
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> updateProduct(
    String id,
    AdminProductRequestModel request,
  ) async {
    _setSaving(true);

    try {
      final product = await _adminProductService.updateProduct(id, request);
      _selectedProduct = product;
      _products = _products
          .map((item) => item.id == product.id ? product : item)
          .toList();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> uploadProductImages(String productId, List<XFile> files) async {
    _setUploadingImages(true);

    try {
      await _adminProductService.uploadProductImages(productId, files);
      await loadProductDetail(productId);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setUploadingImages(false);
    }
  }

  Future<bool> setProductThumbnail(String productId, String imageId) async {
    _setUpdatingImage(true);

    try {
      await _adminProductService.setProductThumbnail(productId, imageId);
      await loadProductDetail(productId);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setUpdatingImage(false);
    }
  }

  Future<bool> deleteProductImage(String productId, String imageId) async {
    _setUpdatingImage(true);

    try {
      await _adminProductService.deleteProductImage(productId, imageId);
      await loadProductDetail(productId);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setUpdatingImage(false);
    }
  }

  Future<bool> hideProduct(String id) async {
    _setDeleting(true);

    try {
      await _adminProductService.hideProduct(id);
      await loadProducts();
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

  void _setUploadingImages(bool value) {
    if (_isUploadingImages == value) {
      return;
    }

    _isUploadingImages = value;
    notifyListeners();
  }

  void _setUpdatingImage(bool value) {
    if (_isUpdatingImage == value) {
      return;
    }

    _isUpdatingImage = value;
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
