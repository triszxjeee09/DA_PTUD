import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../auth/data/models/user_model.dart';
import '../data/services/admin_user_service.dart';

class AdminUserProvider extends ChangeNotifier {
  AdminUserProvider({AdminUserService? adminUserService})
    : _adminUserService = adminUserService ?? AdminUserService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminUserService _adminUserService;

  List<UserModel> _users = const [];
  UserModel? _selectedUser;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String _keyword = '';
  String? _status;
  String? _role;
  int _page = 0;
  int _size = 20;
  int _totalPages = 1;
  int _totalElements = 0;
  bool _isLast = true;

  List<UserModel> get users => _users;
  UserModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;
  String? get status => _status;
  String? get role => _role;
  int get page => _page;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get isFirstPage => _page <= 0;
  bool get isLastPage => _isLast || _page >= _totalPages - 1;

  Future<void> loadUsers({
    String? keyword,
    String? status,
    String? role,
    int? page,
  }) async {
    if (keyword != null) {
      _keyword = keyword.trim();
      _page = 0;
    }
    if (status != null) {
      _status = _emptyToNull(status);
      _page = 0;
    }
    if (role != null) {
      _role = _emptyToNull(role);
      _page = 0;
    }
    if (page != null) {
      _page = page < 0 ? 0 : page;
    }

    _setLoading(true);

    try {
      final result = await _adminUserService.getUsers(
        keyword: _keyword,
        status: _status,
        role: _role,
        page: _page,
        size: _size,
      );
      _users = result.content;
      _page = result.page;
      _size = result.size == 0 ? _size : result.size;
      _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
      _totalElements = result.totalElements;
      _isLast = result.last;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> nextPage() {
    if (isLastPage) {
      return Future.value();
    }

    return loadUsers(page: _page + 1);
  }

  Future<void> previousPage() {
    if (isFirstPage) {
      return Future.value();
    }

    return loadUsers(page: _page - 1);
  }

  Future<UserModel?> loadUserDetail(String userId) async {
    _setLoadingDetail(true);

    try {
      _selectedUser = await _adminUserService.getUserDetail(userId);
      _replaceUser(_selectedUser!);
      _errorMessage = null;
      return _selectedUser;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return null;
    } finally {
      _setLoadingDetail(false);
    }
  }

  Future<bool> updateStatus(String userId, String status) async {
    return _runUserUpdate(() => _adminUserService.updateStatus(userId, status));
  }

  Future<bool> addRole(String userId, String roleName) async {
    return _runUserUpdate(() => _adminUserService.addRole(userId, roleName));
  }

  Future<bool> removeRole(String userId, String roleName) async {
    return _runUserUpdate(() => _adminUserService.removeRole(userId, roleName));
  }

  Future<bool> _runUserUpdate(Future<UserModel> Function() action) async {
    _setUpdating(true);

    try {
      final user = await action();
      _selectedUser = user;
      _replaceUser(user);
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

  void _replaceUser(UserModel user) {
    _users = _users.map((item) => item.id == user.id ? user : item).toList();
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setLoadingDetail(bool value) {
    if (_isLoadingDetail == value) {
      return;
    }

    _isLoadingDetail = value;
    notifyListeners();
  }

  void _setUpdating(bool value) {
    if (_isUpdating == value) {
      return;
    }

    _isUpdating = value;
    notifyListeners();
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
