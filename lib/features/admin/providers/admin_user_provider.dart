import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/admin_user_model.dart';
import '../data/services/admin_user_service.dart';

class AdminUserProvider extends ChangeNotifier {
  AdminUserProvider({AdminUserService? adminUserService})
    : _adminUserService = adminUserService ?? AdminUserService();

  static const int _pageSize = 10;
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminUserService _adminUserService;

  final List<AdminUserModel> _users = [];
  AdminUserModel? _selectedUser;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isUpdatingStatus = false;
  bool _isUpdatingRole = false;
  bool _isBlockingUser = false;
  bool _isUnlockingUser = false;
  bool _isAssigningRole = false;
  bool _isRemovingRole = false;
  bool _isResettingPassword = false;
  bool _isDeactivatingUser = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentKeyword;
  String? _currentStatusFilter;
  String? _currentRoleFilter;

  List<AdminUserModel> get users => List.unmodifiable(_users);
  AdminUserModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isUpdatingStatus => _isUpdatingStatus;
  bool get isUpdatingRole => _isUpdatingRole;
  bool get isBlockingUser => _isBlockingUser;
  bool get isUnlockingUser => _isUnlockingUser;
  bool get isAssigningRole => _isAssigningRole;
  bool get isRemovingRole => _isRemovingRole;
  bool get isResettingPassword => _isResettingPassword;
  bool get isDeactivatingUser => _isDeactivatingUser;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get currentKeyword => _currentKeyword;
  String? get currentStatusFilter => _currentStatusFilter;
  String? get currentRoleFilter => _currentRoleFilter;

  Future<void> loadUsers({
    bool refresh = false,
    String? keyword,
    String? status,
    String? role,
  }) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh) {
      _currentPage = 0;
      _users.clear();
      _hasMore = true;
      _currentKeyword = keyword == null
          ? _currentKeyword
          : _emptyToNull(keyword);
      _currentStatusFilter = status == null
          ? _currentStatusFilter
          : _emptyToNull(status);
      _currentRoleFilter = role == null
          ? _currentRoleFilter
          : _emptyToNull(role);
    } else {
      _currentKeyword = keyword == null
          ? _currentKeyword
          : _emptyToNull(keyword);
      _currentStatusFilter = status == null
          ? _currentStatusFilter
          : _emptyToNull(status);
      _currentRoleFilter = role == null
          ? _currentRoleFilter
          : _emptyToNull(role);
    }

    if (!_hasMore) {
      notifyListeners();
      return;
    }

    final isFirstPage = _currentPage == 0;
    _errorMessage = null;
    _setListLoading(isFirstPage: isFirstPage, value: true);

    try {
      debugPrint(
        'AdminUserProvider: load users page=$_currentPage, '
        'keyword=${_currentKeyword ?? '-'}, '
        'status=${_currentStatusFilter ?? '-'}, '
        'role=${_currentRoleFilter ?? '-'}',
      );

      final result = await _adminUserService.getUsers(
        page: _currentPage,
        size: _pageSize,
        keyword: _currentKeyword,
        status: _currentStatusFilter,
        role: _currentRoleFilter,
      );

      _appendUniqueUsers(result.content);
      _currentPage = result.page >= _currentPage
          ? result.page + 1
          : _currentPage + 1;
      _hasMore = !result.last;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setListLoading(isFirstPage: isFirstPage, value: false);
    }
  }

  Future<void> loadUserDetail(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      _errorMessage = 'Không tìm thấy mã người dùng';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _adminUserService.getUserById(normalizedUserId);
      _selectedUser = user;
      _replaceUser(user);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedStatus = status.trim();
    if (normalizedUserId.isEmpty || normalizedStatus.isEmpty) {
      _errorMessage = 'Dữ liệu người dùng không hợp lệ';
      notifyListeners();
      return false;
    }

    _isUpdatingStatus = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _adminUserService.updateUserStatus(
        userId: normalizedUserId,
        status: normalizedStatus,
      );
      _applyUpdatedUser(user);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  Future<bool> blockUser(String userId) {
    return _runUserMutation(
      userId: userId,
      setLoading: (value) => _isBlockingUser = value,
      action: (normalizedUserId) =>
          _adminUserService.blockUser(normalizedUserId),
    );
  }

  Future<bool> unlockUser(String userId) {
    return _runUserMutation(
      userId: userId,
      setLoading: (value) => _isUnlockingUser = value,
      action: (normalizedUserId) =>
          _adminUserService.unlockUser(normalizedUserId),
    );
  }

  Future<bool> assignRole(String userId, String roleName) {
    return _runUserMutation(
      userId: userId,
      setLoading: (value) {
        _isAssigningRole = value;
        _isUpdatingRole = value;
      },
      action: (normalizedUserId) => _adminUserService.assignRole(
        userId: normalizedUserId,
        roleName: roleName.trim(),
      ),
    );
  }

  Future<bool> removeRole(String userId, String roleName) {
    return _runUserMutation(
      userId: userId,
      setLoading: (value) {
        _isRemovingRole = value;
        _isUpdatingRole = value;
      },
      action: (normalizedUserId) => _adminUserService.removeRole(
        userId: normalizedUserId,
        roleName: roleName.trim(),
      ),
    );
  }

  Future<bool> resetPassword(
    String userId,
    String newPassword,
    String confirmPassword,
  ) {
    return _runUserMutation(
      userId: userId,
      setLoading: (value) => _isResettingPassword = value,
      action: (normalizedUserId) => _adminUserService.resetPassword(
        userId: normalizedUserId,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
  }

  Future<bool> deactivateUser(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      _errorMessage = 'Không tìm thấy mã người dùng';
      notifyListeners();
      return false;
    }

    _isDeactivatingUser = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminUserService.deactivateUser(normalizedUserId);
      _removeUser(normalizedUserId);
      if (_selectedUser?.id == normalizedUserId) {
        _selectedUser = null;
      }
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _isDeactivatingUser = false;
      notifyListeners();
    }
  }

  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runUserMutation({
    required String userId,
    required ValueChanged<bool> setLoading,
    required Future<AdminUserModel?> Function(String userId) action,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      _errorMessage = 'Không tìm thấy mã người dùng';
      notifyListeners();
      return false;
    }

    setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await action(normalizedUserId);
      if (user != null) {
        _applyUpdatedUser(user);
      } else {
        await _loadUserDetailSilently(normalizedUserId);
      }
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> _loadUserDetailSilently(String userId) async {
    final user = await _adminUserService.getUserById(userId);
    _applyUpdatedUser(user);
  }

  void _applyUpdatedUser(AdminUserModel user) {
    _selectedUser = user;
    _replaceUser(user);
  }

  void _replaceUser(AdminUserModel user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    }
  }

  void _removeUser(String userId) {
    _users.removeWhere((item) => item.id == userId);
  }

  void _appendUniqueUsers(List<AdminUserModel> users) {
    final existingIds = _users.map((user) => user.id).toSet();
    for (final user in users) {
      if (user.id.isEmpty || existingIds.add(user.id)) {
        _users.add(user);
      }
    }
  }

  void _setListLoading({required bool isFirstPage, required bool value}) {
    if (isFirstPage) {
      _isLoading = value;
    } else {
      _isLoadingMore = value;
    }
    notifyListeners();
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
