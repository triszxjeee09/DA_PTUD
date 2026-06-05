import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/admin_activity_log_model.dart';
import '../data/services/admin_activity_log_service.dart';

class AdminActivityLogProvider extends ChangeNotifier {
  AdminActivityLogProvider({AdminActivityLogService? adminActivityLogService})
    : _adminActivityLogService =
          adminActivityLogService ?? AdminActivityLogService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const int _pageSize = 20;

  final AdminActivityLogService _adminActivityLogService;

  List<AdminActivityLogModel> _logs = const [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String _keyword = '';
  String? _action;
  String? _entityName;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<AdminActivityLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String get keyword => _keyword;
  String? get action => _action;
  String? get entityName => _entityName;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  Future<void> loadLogs({
    bool refresh = false,
    String? keyword,
    String? action,
    String? entityName,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (keyword != null) {
      _keyword = keyword.trim();
      refresh = true;
    }
    if (action != null) {
      _action = _emptyToNull(action);
      refresh = true;
    }
    if (entityName != null) {
      _entityName = _emptyToNull(entityName);
      refresh = true;
    }
    if (fromDate != null || refresh) {
      _fromDate = fromDate;
    }
    if (toDate != null || refresh) {
      _toDate = toDate;
    }

    if (refresh) {
      _logs = const [];
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = _currentPage;
    if (_logs.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _adminActivityLogService.getLogs(
        page: pageToLoad,
        size: _pageSize,
        keyword: _keyword,
        action: _action,
        entityName: _entityName,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      _logs = pageToLoad == 0
          ? pageResponse.content
          : [..._logs, ...pageResponse.content];
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

  void clearFilters() {
    _keyword = '';
    _action = null;
    _entityName = null;
    _fromDate = null;
    _toDate = null;
    loadLogs(refresh: true);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) {
      return;
    }

    _isLoadingMore = value;
    notifyListeners();
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 403) {
        return 'Bạn không có quyền xem lịch sử hoạt động';
      }
      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
    }

    return _defaultErrorMessage;
  }
}
