import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/cancel_order_request_model.dart';
import '../data/models/create_order_request_model.dart';
import '../data/models/order_detail_model.dart';
import '../data/models/order_model.dart';
import '../data/models/order_status_history_model.dart';
import '../data/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderService? orderService})
    : _orderService = orderService ?? OrderService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const int _pageSize = 10;

  final OrderService _orderService;

  List<OrderModel> _orders = const [];
  OrderDetailModel? _selectedOrder;
  List<OrderStatusHistoryModel> _statusHistories = const [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentStatus;

  List<OrderModel> get orders => _orders;
  OrderDetailModel? get selectedOrder => _selectedOrder;
  List<OrderStatusHistoryModel> get statusHistories => _statusHistories;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  Future<bool> createOrder(CreateOrderRequestModel request) async {
    _setCreating(true);
    debugPrint('[ORDER] Bắt đầu tạo đơn hàng');

    try {
      _selectedOrder = await _orderService.createOrder(request);
      debugPrint(
        '[ORDER] Tạo đơn hàng thành công: ${_selectedOrder?.orderCode ?? ''}',
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      debugPrint('[ORDER] Tạo đơn hàng thất bại: $_errorMessage');
      return false;
    } finally {
      _setCreating(false);
    }
  }

  Future<void> loadMyOrders({String? status, bool refresh = false}) async {
    final normalizedStatus = _normalizeStatus(status);
    final statusChanged = normalizedStatus != _currentStatus;

    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh || statusChanged) {
      _orders = const [];
      _currentPage = 0;
      _hasMore = true;
      _currentStatus = normalizedStatus;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = _currentPage;
    if (_orders.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _orderService.getMyOrders(
        page: pageToLoad,
        size: _pageSize,
        status: _currentStatus,
      );

      _orders = pageToLoad == 0
          ? pageResponse.content
          : [..._orders, ...pageResponse.content];
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

  Future<void> loadOrderDetail(String orderId) async {
    _setLoading(true);

    try {
      _selectedOrder = await _orderService.getOrderDetail(orderId);
      _statusHistories = _selectedOrder?.statusHistories ?? const [];
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStatusHistory(String orderId) async {
    _setLoading(true);

    try {
      _statusHistories = await _orderService.getOrderStatusHistory(orderId);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    _setCreating(true);

    try {
      _selectedOrder = await _orderService.cancelOrder(
        orderId,
        CancelOrderRequestModel(reason: reason),
      );
      _statusHistories = _selectedOrder?.statusHistories ?? _statusHistories;
      _errorMessage = null;
      await loadMyOrders(status: _currentStatus, refresh: true);
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setCreating(false);
    }
  }

  void clearSelectedOrder() {
    if (_selectedOrder == null && _statusHistories.isEmpty) {
      return;
    }

    _selectedOrder = null;
    _statusHistories = const [];
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

  void _setCreating(bool value) {
    if (_isCreating == value) {
      return;
    }

    _isCreating = value;
    notifyListeners();
  }

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) {
      return;
    }

    _isLoadingMore = value;
    notifyListeners();
  }

  String? _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) {
      return null;
    }

    return status.trim();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
