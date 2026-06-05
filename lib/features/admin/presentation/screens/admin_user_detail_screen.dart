import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_user_provider.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _didStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AdminUserProvider>().loadUserDetail(widget.userId);
    });
  }

  Future<void> _updateStatus(String status) async {
    final provider = context.read<AdminUserProvider>();
    final success = await provider.updateStatus(widget.userId, status);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Cập nhật trạng thái thành công'
          : provider.errorMessage ?? 'Không thể cập nhật trạng thái.',
    );
  }

  Future<void> _addRole() async {
    final role = await _selectRole(title: 'Gán vai trò');
    if (role == null || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.addRole(widget.userId, role);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Gán vai trò thành công'
          : provider.errorMessage ?? 'Không thể gán vai trò.',
    );
  }

  Future<void> _removeRole(String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa vai trò'),
          content: Text('Bạn có chắc chắn muốn xóa vai trò "$role" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    final success = await provider.removeRole(
      widget.userId,
      _normalizeRole(role),
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Xóa vai trò thành công'
          : provider.errorMessage ?? 'Không thể xóa vai trò.',
    );
  }

  Future<String?> _selectRole({required String title}) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final role in const ['CUSTOMER', 'ADMIN', 'PHARMACIST'])
                ListTile(
                  leading: const Icon(Icons.verified_user_rounded),
                  title: Text(role),
                  onTap: () => Navigator.of(context).pop(role),
                ),
            ],
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
    final user = provider.selectedUser?.id == widget.userId
        ? provider.selectedUser
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết người dùng')),
      body: Builder(
        builder: (context) {
          if (provider.isLoadingDetail && user == null) {
            return const AppLoading(message: 'Đang tải người dùng...');
          }

          if (provider.errorMessage != null && user == null) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.loadUserDetail(widget.userId),
            );
          }

          if (user == null) {
            return const Center(child: Text('Không tìm thấy người dùng.'));
          }

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => provider.loadUserDetail(widget.userId),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _UserHeader(user: user),
                const SizedBox(height: 16),
                _InfoCard(user: user),
                const SizedBox(height: 16),
                _ActionCard(
                  user: user,
                  isBusy: provider.isUpdating,
                  onBlock: () => _updateStatus('BLOCKED'),
                  onUnblock: () => _updateStatus('ACTIVE'),
                  onAddRole: _addRole,
                  onRemoveRole: _removeRole,
                ),
                if (provider.isUpdating) ...[
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

  String _normalizeRole(String role) {
    final normalized = role.trim().toUpperCase();
    return normalized.startsWith('ROLE_')
        ? normalized.substring('ROLE_'.length)
        : normalized;
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: AppTheme.lightBlue,
              backgroundImage: user.avatarUrl?.trim().isNotEmpty == true
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl?.trim().isNotEmpty == true
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryBlue,
                      size: 38,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fallback(user.fullName, 'Chưa có họ tên'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_fallback(user.email, 'Chưa có email')),
                  const SizedBox(height: 10),
                  _StatusChip(status: user.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fallback(String? value, String fallback) {
    final text = value?.trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin user',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Email', value: _fallback(user.email)),
            _InfoRow(label: 'Số điện thoại', value: _fallback(user.phone)),
            _InfoRow(label: 'Giới tính', value: _fallback(user.gender)),
            _InfoRow(
              label: 'Ngày sinh',
              value: user.dateOfBirth == null
                  ? 'Chưa có'
                  : DateFormatter.formatDate(user.dateOfBirth!),
            ),
            _InfoRow(label: 'Trạng thái', value: _fallback(user.status)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.roles.isEmpty
                  ? [const Chip(label: Text('Chưa có vai trò'))]
                  : user.roles.map((role) => Chip(label: Text(role))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _fallback(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Chưa có' : text;
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
            width: 110,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.user,
    required this.isBusy,
    required this.onBlock,
    required this.onUnblock,
    required this.onAddRole,
    required this.onRemoveRole,
  });

  final UserModel user;
  final bool isBusy;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onAddRole;
  final ValueChanged<String> onRemoveRole;

  @override
  Widget build(BuildContext context) {
    final isBlocked = user.status?.trim().toUpperCase() == 'BLOCKED';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chức năng',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (isBlocked)
              ElevatedButton.icon(
                onPressed: isBusy ? null : onUnblock,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Mở khóa tài khoản'),
              )
            else
              OutlinedButton.icon(
                onPressed: isBusy ? null : onBlock,
                icon: const Icon(Icons.lock_rounded),
                label: const Text('Khóa tài khoản'),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isBusy ? null : onAddRole,
              icon: const Icon(Icons.add_moderator_rounded),
              label: const Text('Gán role'),
            ),
            const SizedBox(height: 12),
            Text(
              'Xóa role',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (user.roles.isEmpty)
              const Text('Người dùng chưa có vai trò.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.roles.map((role) {
                  return InputChip(
                    label: Text(role),
                    deleteIcon: const Icon(Icons.close_rounded),
                    onDeleted: isBusy ? null : () => onRemoveRole(role),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = status?.trim().toUpperCase() ?? 'INACTIVE';
    final color = normalized == 'BLOCKED'
        ? AppTheme.error
        : normalized == 'ACTIVE'
        ? AppTheme.success
        : AppTheme.textSecondary;

    return Chip(
      label: Text(normalized),
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
