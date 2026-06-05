import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/admin_dashboard_model.dart';
import '../data/models/order_status_statistic_model.dart';
import '../data/models/revenue_statistic_model.dart';
import '../data/services/admin_dashboard_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider({AdminDashboardService? adminDashboardService})
    : _adminDashboardService = adminDashboardService ?? AdminDashboardService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminDashboardService _adminDashboardService;

  AdminDashboardModel? _overview;
  List<OrderStatusStatisticModel> _orderStatusStatistics = const [];
  List<RevenueStatisticModel> _revenueStatistics = const [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminDashboardModel? get overview => _overview;
  List<OrderStatusStatisticModel> get orderStatusStatistics =>
      _orderStatusStatistics;
  List<RevenueStatisticModel> get revenueStatistics => _revenueStatistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _setLoading(true);

    try {
      final results = await Future.wait<Object>([
        _adminDashboardService.getOverview(),
        _adminDashboardService.getOrderStatusStatistics(),
        _adminDashboardService.getRevenueLast7Days(),
      ]);

      _overview = results[0] as AdminDashboardModel;
      _orderStatusStatistics = results[1] as List<OrderStatusStatisticModel>;
      _revenueStatistics = results[2] as List<RevenueStatisticModel>;
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
