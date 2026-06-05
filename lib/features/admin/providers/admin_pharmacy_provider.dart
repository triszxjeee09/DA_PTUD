import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../pharmacy/data/models/pharmacy_model.dart';
import '../data/models/admin_pharmacy_request_model.dart';
import '../data/services/admin_pharmacy_service.dart';

class AdminPharmacyProvider extends ChangeNotifier {
  AdminPharmacyProvider({AdminPharmacyService? adminPharmacyService})
    : _adminPharmacyService = adminPharmacyService ?? AdminPharmacyService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminPharmacyService _adminPharmacyService;

  List<PharmacyModel> _pharmacies = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String _keyword = '';

  List<PharmacyModel> get pharmacies {
    final keyword = _keyword.toLowerCase().trim();
    if (keyword.isEmpty) {
      return _pharmacies;
    }

    return _pharmacies.where((pharmacy) {
      return pharmacy.name.toLowerCase().contains(keyword) ||
          pharmacy.province.toLowerCase().contains(keyword) ||
          pharmacy.district.toLowerCase().contains(keyword) ||
          (pharmacy.ward ?? '').toLowerCase().contains(keyword) ||
          pharmacy.address.toLowerCase().contains(keyword) ||
          (pharmacy.fullAddress ?? '').toLowerCase().contains(keyword);
    }).toList();
  }

  List<PharmacyModel> get allPharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;

  Future<void> loadPharmacies({String? keyword}) async {
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    _setLoading(true);

    try {
      _pharmacies = await _adminPharmacyService.getPharmacies();
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

  Future<bool> createPharmacy(AdminPharmacyRequestModel request) async {
    _setSaving(true);

    try {
      await _adminPharmacyService.createPharmacy(request);
      await loadPharmacies();
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

  Future<bool> updatePharmacy(
    String id,
    AdminPharmacyRequestModel request,
  ) async {
    _setSaving(true);

    try {
      await _adminPharmacyService.updatePharmacy(id, request);
      await loadPharmacies();
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

  Future<bool> deletePharmacy(String id) async {
    _setDeleting(true);

    try {
      await _adminPharmacyService.deletePharmacy(id);
      await loadPharmacies();
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

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
