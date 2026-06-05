import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/brand_model.dart';
import '../data/services/brand_service.dart';

class BrandProvider extends ChangeNotifier {
  BrandProvider({BrandService? brandService})
    : _brandService = brandService ?? BrandService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final BrandService _brandService;

  List<BrandModel> _brands = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBrands() async {
    _setLoading(true);

    try {
      _brands = await _brandService.getBrands();
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
