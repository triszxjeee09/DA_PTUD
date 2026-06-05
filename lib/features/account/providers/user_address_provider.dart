import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/user_address_model.dart';
import '../data/models/user_address_request_model.dart';
import '../data/services/user_address_service.dart';

class UserAddressProvider extends ChangeNotifier {
  UserAddressProvider({UserAddressService? userAddressService})
    : _userAddressService = userAddressService ?? UserAddressService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final UserAddressService _userAddressService;

  List<UserAddressModel> _addresses = const [];
  UserAddressModel? _selectedAddress;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<UserAddressModel> get addresses => _addresses;
  UserAddressModel? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  UserAddressModel? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) {
        return address;
      }
    }

    return null;
  }

  Future<void> loadAddresses() async {
    _setLoading(true);

    try {
      _addresses = await _userAddressService.getMyAddresses();
      _syncSelectedAddress();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  void selectAddress(UserAddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<bool> createAddress(UserAddressRequestModel request) {
    return _saveAndReload(() => _userAddressService.createAddress(request));
  }

  Future<bool> updateAddress(String id, UserAddressRequestModel request) {
    return _saveAndReload(() => _userAddressService.updateAddress(id, request));
  }

  Future<bool> deleteAddress(String id) {
    return _saveAndReload(() => _userAddressService.deleteAddress(id));
  }

  Future<bool> setDefaultAddress(String id) {
    return _saveAndReload(() => _userAddressService.setDefaultAddress(id));
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _saveAndReload(Future<void> Function() action) async {
    _setSaving(true);

    try {
      await action();
      await loadAddresses();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setSaving(false);
    }
  }

  void _syncSelectedAddress() {
    if (_addresses.isEmpty) {
      _selectedAddress = null;
      return;
    }

    final defaultAddress = this.defaultAddress;
    if (defaultAddress != null) {
      _selectedAddress = defaultAddress;
      return;
    }

    final selectedId = _selectedAddress?.id;
    UserAddressModel? selectedStillExists;
    if (selectedId != null) {
      for (final address in _addresses) {
        if (address.id == selectedId) {
          selectedStillExists = address;
          break;
        }
      }
    }

    _selectedAddress = selectedStillExists ?? _addresses.first;
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

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
