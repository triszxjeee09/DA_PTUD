import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/firebase/firebase_messaging_config.dart';
import '../data/models/device_token_model.dart';
import '../data/models/save_device_token_request_model.dart';
import '../data/services/device_token_service.dart';

class DeviceTokenProvider extends ChangeNotifier {
  DeviceTokenProvider({DeviceTokenService? deviceTokenService})
    : _deviceTokenService = deviceTokenService ?? DeviceTokenService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DeviceTokenService _deviceTokenService;

  List<DeviceTokenModel> _deviceTokens = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<DeviceTokenModel> get deviceTokens => _deviceTokens;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<bool> saveCurrentDeviceToken() async {
    _setSaving(true);

    try {
      final token = await FirebaseMessagingConfig.getFcmToken();
      if (token == null || token.trim().isEmpty) {
        _errorMessage = null;
        return false;
      }

      final savedToken = await _deviceTokenService.saveDeviceToken(
        SaveDeviceTokenRequestModel(token: token, platform: _currentPlatform()),
      );

      _upsertDeviceToken(savedToken);
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

  Future<void> loadMyDeviceTokens() async {
    _setLoading(true);

    try {
      _deviceTokens = await _deviceTokenService.getMyDeviceTokens();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deactivateDeviceToken(String token) async {
    _setSaving(true);

    try {
      await _deviceTokenService.deactivateDeviceToken(token);
      _deviceTokens = _deviceTokens
          .where((deviceToken) => deviceToken.token != token)
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

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _upsertDeviceToken(DeviceTokenModel savedToken) {
    final index = _deviceTokens.indexWhere(
      (deviceToken) => deviceToken.token == savedToken.token,
    );

    if (index < 0) {
      _deviceTokens = [..._deviceTokens, savedToken];
    } else {
      final nextDeviceTokens = [..._deviceTokens];
      nextDeviceTokens[index] = savedToken;
      _deviceTokens = nextDeviceTokens;
    }

    notifyListeners();
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

  String _currentPlatform() {
    if (kIsWeb) {
      return 'WEB';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return 'UNKNOWN';
    }
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
