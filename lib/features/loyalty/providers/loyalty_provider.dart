import 'package:flutter/foundation.dart';

import '../../../core/network/json_api.dart';
import '../data/loyalty_models.dart';

class LoyaltyProvider extends ChangeNotifier {
  LoyaltyProvider({JsonApi? api}) : _api = api ?? JsonApi();

  final JsonApi _api;

  String? _userId;
  LoyaltySummary? _summary;
  bool _isLoading = false;
  bool _isRedeeming = false;
  String? _errorMessage;

  LoyaltySummary? get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isRedeeming => _isRedeeming;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _summary = LoyaltySummary.fromJson(
        JsonApi.asMap(await _api.get('/loyalty')),
      );
    } catch (error) {
      _errorMessage = JsonApi.message(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đổi điểm lấy voucher. Trả về mã voucher, hoặc `null` nếu lỗi.
  Future<String?> redeem(String rewardId) async {
    _isRedeeming = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = JsonApi.asMap(
        await _api.post('/loyalty/redeem', body: {'rewardId': rewardId}),
      );
      _summary = LoyaltySummary.fromJson(JsonApi.asMap(data['summary']));
      return JsonApi.asMap(data['voucher'])['code']?.toString();
    } catch (error) {
      _errorMessage = JsonApi.message(error);
      return null;
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }
  }

  void resetIfUserChanged(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _summary = null;
      _errorMessage = null;
    }
  }

  void clear() {
    _summary = null;
    _errorMessage = null;
    notifyListeners();
  }
}
