import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_user_model.dart';
import '../../providers/admin_user_provider.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_userId.isEmpty) {
        _showMessage('Không tìm thấy mã người dùng');
        Navigator.of(context).pop(false);
        return;
      }

      context.read<AdminUserProvider>().loadUserDetail(_userId);
    });
  }

  Future<void> _refreshUser() {
    if (_userId.isEmpty) {
      return Future<void>.value();
    }

    return context.read<AdminUserProvider>().loadUserDetail(_userId);
  }

  Future<void> _confirmBlockUser(AdminUserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Khóa tài khoản',
      content:
          'Bạn có chắc chắn muốn khóa tài khoản này không? Người dùng sẽ không thể đăng nhập.',
      confirmText: 'Khóa tài khoản',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.blockUser(_userId);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Khóa tài khoản thành công'
          : provider.errorMessage ?? 'Không thể khóa tài khoản',
    );
  }

  Future<void> _confirmUnlockUser(AdminUserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Mở khóa tài khoản',
      content:
          'Bạn có chắc chắn muốn mở khóa tài khoản "${_displayName(user)}" không?',
      confirmText: 'Mở khóa',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.unlockUser(_userId);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Mở khóa tài khoản thành công'
          : provider.errorMessage ?? 'Không thể mở khóa tài khoản',
    );
  }

  Future<void> _confirmActivateUser(AdminUserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Kích hoạt tài khoản',
      content:
          'Bạn có chắc chắn muốn kích hoạt tài khoản "${_displayName(user)}" không?',
      confirmText: 'Kích hoạt',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.updateUserStatus(
      userId: _userId,
      status: 'ACTIVE',
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Kích hoạt tài khoản thành công'
          : provider.errorMessage ?? 'Không thể kích hoạt tài khoản',
    );
  }

  Future<void> _confirmDeactivateUser(AdminUserModel user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Vô hiệu hóa tài khoản',
      content:
          'Tài khoản sẽ chuyển sang trạng thái ngừng hoạt động. Dữ liệu đơn hàng và giao dịch vẫn được giữ lại.',
      confirmText: 'Vô hiệu hóa',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.deactivateUser(_userId);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Vô hiệu hóa tài khoản thành công'
          : provider.errorMessage ?? 'Không thể vô hiệu hóa tài khoản',
    );

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmResetPassword(AdminUserModel user) async {
    final input = await _showResetPasswordDialog(user);
    if (input == null || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.resetPassword(
      _userId,
      input.newPassword,
      input.confirmPassword,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Đặt lại mật khẩu thành công'
          : provider.errorMessage ?? 'Không thể đặt lại mật khẩu',
    );
  }

  Future<void> _assignRole(AdminUserModel user) async {
    final role = await _selectRole(user.roles);
    if (role == null || !mounted) {
      return;
    }

    if (role == 'ADMIN') {
      final confirmed = await _showConfirmDialog(
        title: 'Gán vai trò quản trị viên',
        content:
            'Vai trò Quản trị viên có toàn quyền quản lý hệ thống. Bạn có chắc chắn muốn gán vai trò này không?',
        confirmText: 'Gán vai trò',
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.assignRole(_userId, role);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Gán vai trò thành công'
          : provider.errorMessage ?? 'Không thể gán vai trò',
    );
  }

  Future<void> _removeRole(AdminUserModel user, String role) async {
    final roleName = _normalizeRole(role);
    final isLastRole = user.roles.length <= 1;
    final currentUser = context.read<AuthProvider>().currentUser;
    final isSelfAdminRole = currentUser?.id == user.id && roleName == 'ADMIN';

    if (isLastRole || isSelfAdminRole) {
      _showMessage(
        isSelfAdminRole
            ? 'Bạn không thể xóa vai trò ADMIN của chính mình'
            : 'Người dùng phải còn ít nhất một vai trò',
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Xóa vai trò',
      content:
          'Bạn có chắc chắn muốn xóa vai trò "${_roleLabel(roleName)}" không?',
      confirmText: 'Xóa',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.removeRole(_userId, roleName);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Xóa vai trò thành công'
          : provider.errorMessage ?? 'Không thể xóa vai trò',
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: isDestructive
                  ? FilledButton.styleFrom(backgroundColor: AppTheme.error)
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<_ResetPasswordInput?> _showResetPasswordDialog(AdminUserModel user) {
    return showDialog<_ResetPasswordInput>(
      context: context,
      builder: (_) => _ResetPasswordDialog(userName: _displayName(user)),
    );
  }

  Future<String?> _selectRole(List<String> currentRoles) {
    final currentRoleSet = currentRoles.map(_normalizeRole).toSet();

    return showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Gán vai trò',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final role in const ['CUSTOMER', 'PHARMACIST', 'ADMIN'])
                  ListTile(
                    leading: const Icon(Icons.verified_user_rounded),
                    title: Text(_roleLabel(role)),
                    subtitle: Text(role),
                    trailing: currentRoleSet.contains(role)
                        ? const Text(
                            'Đã có',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                    enabled: !currentRoleSet.contains(role),
                    onTap: currentRoleSet.contains(role)
                        ? null
                        : () => Navigator.of(context).pop(role),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    final provider = context.watch<AdminUserProvider>();
    final currentUser = context.select<AuthProvider, String?>(
      (provider) => provider.currentUser?.id,
    );
    final user = provider.selectedUser?.id.trim() == _userId
        ? provider.selectedUser
        : null;
    final isBusy =
        provider.isUpdatingStatus ||
        provider.isUpdatingRole ||
        provider.isBlockingUser ||
        provider.isUnlockingUser ||
        provider.isAssigningRole ||
        provider.isRemovingRole ||
        provider.isResettingPassword ||
        provider.isDeactivatingUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _userId.isEmpty || provider.isLoading
                ? null
                : _refreshUser,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_userId.isEmpty) {
            return const Center(child: Text('Không tìm thấy mã người dùng'));
          }

          if (provider.isLoading) {
            return const AppLoading(message: 'Đang tải người dùng...');
          }

          if (provider.errorMessage != null && user == null) {
            return _ErrorView(
              message: _displayError(provider.errorMessage!),
              onRetry: _refreshUser,
            );
          }

          if (user == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin người dùng'),
            );
          }

          final isSelf = currentUser == user.id;

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: _refreshUser,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _UserHeader(user: user),
                const SizedBox(height: 16),
                _InfoCard(user: user),
                const SizedBox(height: 16),
                _AccountActionsSection(
                  user: user,
                  isBusy: isBusy,
                  isSelf: isSelf,
                  isBlocking: provider.isBlockingUser,
                  isUnlocking: provider.isUnlockingUser,
                  isActivating: provider.isUpdatingStatus,
                  isResettingPassword: provider.isResettingPassword,
                  isDeactivating: provider.isDeactivatingUser,
                  onBlock: () => _confirmBlockUser(user),
                  onUnlock: () => _confirmUnlockUser(user),
                  onActivate: () => _confirmActivateUser(user),
                  onDeactivate: () => _confirmDeactivateUser(user),
                  onResetPassword: () => _confirmResetPassword(user),
                ),
                const SizedBox(height: 16),
                _RoleSection(
                  user: user,
                  isBusy: isBusy,
                  isAssigningRole: provider.isAssigningRole,
                  isRemovingRole: provider.isRemovingRole,
                  isSelf: isSelf,
                  onAssignRole: () => _assignRole(user),
                  onRemoveRole: (role) => _removeRole(user, role),
                ),
                if (isBusy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('403') || normalized.contains('quyền')) {
      return 'Bạn không có quyền quản lý người dùng';
    }

    return message;
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toUpperCase();
    return normalized.startsWith('ROLE_')
        ? normalized.substring('ROLE_'.length)
        : normalized;
  }

  String _roleLabel(String role) {
    return roleLabel(role);
  }

  String _displayName(AdminUserModel user) {
    final fullName = user.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final username = user.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }

    return user.id;
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _UserAvatar(avatarUrl: user.avatarUrl),
            const SizedBox(height: 12),
            Text(
              _fallback(user.fullName),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              _fallback(user.email),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(_fallback(user.phone), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            _StatusChip(status: user.status),
            const SizedBox(height: 10),
            _RoleChips(roles: user.roles),
          ],
        ),
      ),
    );
  }

  String _fallback(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Chưa cập nhật' : text;
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final fallback = Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        color: AppTheme.lightBlue,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppTheme.primaryBlue,
        size: 46,
      ),
    );

    if (url == null || url.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _ResetPasswordInput {
  const _ResetPasswordInput({
    required this.newPassword,
    required this.confirmPassword,
  });

  final String newPassword;
  final String confirmPassword;
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.userName});

  final String userName;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đặt lại mật khẩu'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nhập mật khẩu mới cho "${widget.userName}".',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final text = value ?? '';
                if (text.trim().isEmpty) {
                  return 'Vui lòng nhập mật khẩu mới';
                }

                if (text.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword
                      ? 'Hiện xác nhận mật khẩu'
                      : 'Ẩn xác nhận mật khẩu',
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final text = value ?? '';
                if (text.trim().isEmpty) {
                  return 'Vui lòng xác nhận mật khẩu';
                }

                if (text != _passwordController.text) {
                  return 'Mật khẩu xác nhận không khớp';
                }

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }

            Navigator.of(context).pop(
              _ResetPasswordInput(
                newPassword: _passwordController.text,
                confirmPassword: _confirmController.text,
              ),
            );
          },
          child: const Text('Đặt lại mật khẩu'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin tài khoản',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'ID người dùng', value: _fallback(user.id)),
            _InfoRow(label: 'Tên đăng nhập', value: _fallback(user.username)),
            _InfoRow(label: 'Họ và tên', value: _fallback(user.fullName)),
            _InfoRow(label: 'Email', value: _fallback(user.email)),
            _InfoRow(label: 'Số điện thoại', value: _fallback(user.phone)),
            _InfoRow(label: 'Giới tính', value: genderLabel(user.gender)),
            _InfoRow(
              label: 'Ngày sinh',
              value: _formatDateOfBirth(user.dateOfBirth),
            ),
            _InfoRow(
              label: 'Provider đăng nhập',
              value: authProviderLabel(user.authProvider),
            ),
            _InfoRow(label: 'Ngày tạo', value: _formatDateTime(user.createdAt)),
            _InfoRow(
              label: 'Ngày cập nhật',
              value: _formatDateTime(user.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  String _fallback(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Chưa cập nhật' : text;
  }

  String _formatDateOfBirth(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return 'Chưa cập nhật';
    }

    final parsedDate = DateTime.tryParse(text);
    return parsedDate == null ? text : DateFormatter.formatDate(parsedDate);
  }

  String _formatDateTime(DateTime? value) {
    return value == null
        ? 'Chưa cập nhật'
        : DateFormatter.formatDateTime(value);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActionsSection extends StatelessWidget {
  const _AccountActionsSection({
    required this.user,
    required this.isBusy,
    required this.isSelf,
    required this.isBlocking,
    required this.isUnlocking,
    required this.isActivating,
    required this.isResettingPassword,
    required this.isDeactivating,
    required this.onBlock,
    required this.onUnlock,
    required this.onActivate,
    required this.onDeactivate,
    required this.onResetPassword,
  });

  final AdminUserModel user;
  final bool isBusy;
  final bool isSelf;
  final bool isBlocking;
  final bool isUnlocking;
  final bool isActivating;
  final bool isResettingPassword;
  final bool isDeactivating;
  final VoidCallback onBlock;
  final VoidCallback onUnlock;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    final status = user.status.trim().toUpperCase();
    final isInactive = status == 'INACTIVE';
    final statusAction = switch (status) {
      'BLOCKED' => _AccountStatusAction(
        icon: Icons.lock_open_rounded,
        title: 'Mở khóa tài khoản',
        subtitle: 'Cho phép tài khoản hoạt động trở lại',
        isDestructive: false,
        isLoading: isUnlocking,
        onPressed: onUnlock,
      ),
      'INACTIVE' => _AccountStatusAction(
        icon: Icons.check_circle_rounded,
        title: 'Kích hoạt tài khoản',
        subtitle: 'Chuyển tài khoản về trạng thái đang hoạt động',
        isDestructive: false,
        isLoading: isActivating,
        onPressed: onActivate,
      ),
      _ => _AccountStatusAction(
        icon: Icons.lock_rounded,
        title: 'Khóa tài khoản',
        subtitle: 'Người dùng sẽ không thể đăng nhập khi tài khoản bị khóa',
        isDestructive: true,
        isLoading: isBlocking,
        onPressed: onBlock,
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thao tác tài khoản',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _StatusChip(status: user.status),
            const SizedBox(height: 12),
            if (isSelf) ...[
              const _SelfActionNotice(),
              const SizedBox(height: 2),
            ],
            _ActionTile(
              icon: statusAction.icon,
              title: statusAction.title,
              subtitle: statusAction.subtitle,
              isDestructive: statusAction.isDestructive,
              isLoading: statusAction.isLoading,
              onPressed: isBusy || (isSelf && status != 'INACTIVE')
                  ? null
                  : statusAction.onPressed,
            ),
            _ActionTile(
              icon: Icons.person_off_rounded,
              title: 'Vô hiệu hóa tài khoản',
              subtitle: isInactive
                  ? 'Tài khoản hiện đang ngừng hoạt động'
                  : 'Chuyển tài khoản sang trạng thái ngừng hoạt động',
              isDestructive: true,
              isLoading: isDeactivating,
              onPressed: isBusy || isInactive || isSelf ? null : onDeactivate,
            ),
            _ActionTile(
              icon: Icons.password_rounded,
              title: 'Đặt lại mật khẩu',
              subtitle: 'Gửi yêu cầu đặt lại mật khẩu cho người dùng',
              isLoading: isResettingPassword,
              onPressed: isBusy ? null : onResetPassword,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatusAction {
  const _AccountStatusAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDestructive,
    required this.isLoading,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback onPressed;
}

class _SelfActionNotice extends StatelessWidget {
  const _SelfActionNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Bạn không thể thực hiện thao tác này trên tài khoản của chính mình',
      style: TextStyle(
        color: AppTheme.warning,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: onPressed == null ? AppTheme.textSecondary : color,
          side: BorderSide(
            color: onPressed == null
                ? const Color(0xFFE5E7EB)
                : color.withValues(alpha: 0.36),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  const _RoleSection({
    required this.user,
    required this.isBusy,
    required this.isAssigningRole,
    required this.isRemovingRole,
    required this.isSelf,
    required this.onAssignRole,
    required this.onRemoveRole,
  });

  final AdminUserModel user;
  final bool isBusy;
  final bool isAssigningRole;
  final bool isRemovingRole;
  final bool isSelf;
  final VoidCallback onAssignRole;
  final ValueChanged<String> onRemoveRole;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Vai trò',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onAssignRole,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  icon: isAssigningRole
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.add_moderator_rounded),
                  label: const Text('Gán vai trò'),
                ),
              ],
            ),
            if (isSelf) ...[
              const SizedBox(height: 8),
              const _SelfActionNotice(),
            ],
            const SizedBox(height: 12),
            if (user.roles.isEmpty)
              const Text('Người dùng chưa có vai trò')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.roles.map((role) {
                  final normalizedRole = normalizeRole(role);
                  final cannotRemove =
                      isBusy ||
                      isRemovingRole ||
                      user.roles.length <= 1 ||
                      (isSelf && normalizedRole == 'ADMIN');

                  return InputChip(
                    label: Text(roleLabel(role)),
                    deleteIcon: isRemovingRole
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded),
                    onDeleted: cannotRemove ? null : () => onRemoveRole(role),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleChips extends StatelessWidget {
  const _RoleChips({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return const Chip(label: Text('Chưa có vai trò'));
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: roles
          .map((role) => Chip(label: Text(roleLabel(role))))
          .toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = status?.trim().toUpperCase() ?? 'INACTIVE';
    final color = switch (normalized) {
      'ACTIVE' => AppTheme.success,
      'BLOCKED' => AppTheme.error,
      _ => AppTheme.textSecondary,
    };

    return Chip(
      label: Text(statusLabel(normalized)),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPermissionView extends StatelessWidget {
  const _NoPermissionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Bạn không có quyền truy cập khu vực Admin.')),
    );
  }
}

String roleLabel(String role) {
  final value = normalizeRole(role);

  switch (value) {
    case 'CUSTOMER':
      return 'Khách hàng';
    case 'ADMIN':
      return 'Quản trị viên';
    case 'PHARMACIST':
      return 'Dược sĩ';
    default:
      return role;
  }
}

String normalizeRole(String role) {
  final normalized = role.trim().toUpperCase();
  return normalized.startsWith('ROLE_')
      ? normalized.substring('ROLE_'.length)
      : normalized;
}

String genderLabel(String? gender) {
  switch (gender?.trim().toUpperCase()) {
    case 'MALE':
      return 'Nam';
    case 'FEMALE':
      return 'Nữ';
    case 'OTHER':
      return 'Khác';
    case null:
    case '':
      return 'Chưa cập nhật';
    default:
      return gender!.trim();
  }
}

String authProviderLabel(String? authProvider) {
  switch (authProvider?.trim().toUpperCase()) {
    case 'LOCAL':
      return 'Tài khoản thường';
    case 'GOOGLE':
      return 'Google';
    case null:
    case '':
      return 'Chưa cập nhật';
    default:
      return authProvider!.trim();
  }
}

String statusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'ACTIVE':
      return 'Đang hoạt động';
    case 'INACTIVE':
      return 'Ngừng hoạt động';
    case 'BLOCKED':
      return 'Đã khóa';
    default:
      return status;
  }
}
