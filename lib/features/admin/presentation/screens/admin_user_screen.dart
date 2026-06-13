import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_user_model.dart';
import '../../providers/admin_user_provider.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _status;
  String? _role;
  bool _didStart = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

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

      _refreshUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > 260) {
      return;
    }

    final provider = context.read<AdminUserProvider>();
    if (provider.hasMore &&
        !provider.isLoading &&
        !provider.isLoadingMore &&
        provider.users.isNotEmpty) {
      provider.loadUsers();
    }
  }

  Future<void> _refreshUsers() {
    return context.read<AdminUserProvider>().loadUsers(
      refresh: true,
      keyword: _searchController.text,
      status: _status ?? '',
      role: _role ?? '',
    );
  }

  Future<void> _openDetail(AdminUserModel user) async {
    final userId = user.id.trim();
    if (userId.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã người dùng')),
      );
      return;
    }

    final result = await Navigator.of(
      context,
    ).pushNamed<bool>(AppRoutes.adminUserDetail, arguments: {'userId': userId});

    if (result == true && mounted) {
      await _refreshUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _refreshUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<AdminUserProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: _refreshUsers,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _UserFilters(
                  searchController: _searchController,
                  status: _status,
                  role: _role,
                  isLoading: provider.isLoading,
                  onStatusChanged: (value) {
                    setState(() => _status = _emptyToNull(value));
                    _refreshUsers();
                  },
                  onRoleChanged: (value) {
                    setState(() => _role = _emptyToNull(value));
                    _refreshUsers();
                  },
                  onSearch: _refreshUsers,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.users.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải người dùng...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.users.isEmpty)
                  _UserErrorView(
                    message: provider.errorMessage!,
                    onRetry: _refreshUsers,
                  )
                else if (provider.users.isEmpty)
                  const _UserEmptyView()
                else ...[
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ...provider.users.map(
                    (user) => _UserCard(
                      user: user,
                      onDetail: () => _openDetail(user),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LoadMoreIndicator(provider: provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _UserFilters extends StatelessWidget {
  const _UserFilters({
    required this.searchController,
    required this.status,
    required this.role,
    required this.isLoading,
    required this.onStatusChanged,
    required this.onRoleChanged,
    required this.onSearch,
    required this.onChanged,
  });

  final TextEditingController searchController;
  final String? status;
  final String? role;
  final bool isLoading;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onRoleChanged;
  final Future<void> Function() onSearch;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Tìm tên, email, số điện thoại',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      searchController.clear();
                      onChanged();
                      onSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: isLoading ? null : onSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: status ?? '',
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả')),
                  DropdownMenuItem(
                    value: 'ACTIVE',
                    child: Text('Đang hoạt động'),
                  ),
                  DropdownMenuItem(
                    value: 'INACTIVE',
                    child: Text('Ngừng hoạt động'),
                  ),
                  DropdownMenuItem(value: 'BLOCKED', child: Text('Đã khóa')),
                ],
                onChanged: isLoading ? null : onStatusChanged,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: role ?? '',
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả')),
                  DropdownMenuItem(
                    value: 'CUSTOMER',
                    child: Text('Khách hàng'),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text('Quản trị viên'),
                  ),
                  DropdownMenuItem(value: 'PHARMACIST', child: Text('Dược sĩ')),
                ],
                onChanged: isLoading ? null : onRoleChanged,
                decoration: const InputDecoration(labelText: 'Vai trò'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onDetail});

  final AdminUserModel user;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.lightBlue,
                  backgroundImage: user.avatarUrl?.trim().isNotEmpty == true
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl?.trim().isNotEmpty == true
                      ? null
                      : const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fallback(user.fullName, 'Chưa có họ tên'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _fallback(user.email, 'Chưa có email'),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: user.status),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.phone_rounded,
              text: 'Số điện thoại: ${_fallback(user.phone, 'Chưa có')}',
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.calendar_month_rounded,
              text: 'Ngày tạo: ${_formatCreatedAt(user.createdAt)}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.roles.isEmpty
                  ? [const Chip(label: Text('Chưa có vai trò'))]
                  : user.roles
                        .map((role) => Chip(label: Text(_roleLabel(role))))
                        .toList(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onDetail,
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Chi tiết'),
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

  String _formatCreatedAt(DateTime? value) {
    return value == null ? 'Chưa có' : DateFormatter.formatDateTime(value);
  }

  String _roleLabel(String role) {
    final normalized = role.trim().toUpperCase();
    final value = normalized.startsWith('ROLE_')
        ? normalized.substring('ROLE_'.length)
        : normalized;

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
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
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
      label: Text(_statusLabel(normalized)),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
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
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator({required this.provider});

  final AdminUserProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!provider.hasMore) {
      return Text(
        'Đã tải hết danh sách người dùng',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

class _UserErrorView extends StatelessWidget {
  const _UserErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
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

class _UserEmptyView extends StatelessWidget {
  const _UserEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: Text('Không có người dùng nào', textAlign: TextAlign.center),
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
