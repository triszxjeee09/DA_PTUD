import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../order/data/models/order_model.dart';
import '../data/services/admin_order_service.dart';

class AdminOrderProvider extends ChangeNotifier {
  AdminOrderProvider({AdminOrderService? adminOrderService})
    : _adminOrderService = adminOrderService ?? AdminOrderService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminOrderService _adminOrderService;

  List<OrderModel> _orders = const [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _selectedStatus;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get selectedStatus => _selectedStatus;

  Future<void> loadOrders({String? status}) async {
    _selectedStatus = status;
    _setLoading(true);

    try {
      final page = await _adminOrderService.getOrders(status: _selectedStatus);
      _orders = page.content;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String id, String status) async {
    _setUpdating(true);

    try {
      await _adminOrderService.updateOrderStatus(id, status);
      await loadOrders(status: _selectedStatus);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setUpdating(bool value) {
    if (_isUpdating == value) return;
    _isUpdating = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
