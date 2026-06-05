import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/pharmacy_model.dart';
import '../data/services/pharmacy_service.dart';

class PharmacyProvider extends ChangeNotifier {
  PharmacyProvider({PharmacyService? pharmacyService})
    : _pharmacyService = pharmacyService ?? PharmacyService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final PharmacyService _pharmacyService;

  List<PharmacyModel> _pharmacies = const [];
  PharmacyModel? _selectedPharmacy;
  bool _isLoading = false;
  String? _errorMessage;

  List<PharmacyModel> get pharmacies => _pharmacies;
  PharmacyModel? get selectedPharmacy => _selectedPharmacy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPharmacies() async {
    _setLoading(true);

    try {
      _pharmacies = await _pharmacyService.getPharmacies();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPharmacyDetail(String id) async {
    if (id.trim().isEmpty) {
      _errorMessage = 'Không tìm thấy nhà thuốc';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      _selectedPharmacy = await _pharmacyService.getPharmacyById(id.trim());
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  void selectPharmacy(PharmacyModel pharmacy) {
    _selectedPharmacy = pharmacy;
    notifyListeners();
  }

  void clearSelectedPharmacy() {
    if (_selectedPharmacy == null) {
      return;
    }

    _selectedPharmacy = null;
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

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
