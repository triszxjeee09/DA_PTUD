import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/notification_model.dart';
import '../data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const int _pageSize = 10;

  final NotificationService _notificationService;

  List<NotificationModel> _notifications = const [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _notifications = const [];
      _currentPage = 0;
      _hasMore = true;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = _currentPage;
    if (_notifications.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _notificationService.getNotifications(
        page: pageToLoad,
        size: _pageSize,
      );

      _notifications = pageToLoad == 0
          ? pageResponse.content
          : [..._notifications, ...pageResponse.content];
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

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final currentIndex = _notifications.indexWhere(
        (notification) => notification.id == id,
      );
      final wasUnread =
          currentIndex >= 0 && !_notifications[currentIndex].isRead;
      final updatedNotification = await _notificationService.markAsRead(id);

      if (currentIndex >= 0) {
        final nextNotifications = [..._notifications];
        nextNotifications[currentIndex] = updatedNotification.isRead
            ? updatedNotification
            : updatedNotification.copyWith(isRead: true);
        _notifications = nextNotifications;
      }

      if (wasUnread && _unreadCount > 0) {
        _unreadCount -= 1;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    }
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

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) {
      return;
    }

    _isLoadingMore = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
