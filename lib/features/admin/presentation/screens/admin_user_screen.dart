import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_user_provider.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _searchController = TextEditingController();
  String? _status;
  String? _role;
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

      context.read<AdminUserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() {
    return context.read<AdminUserProvider>().loadUsers(
      keyword: _searchController.text,
      status: _status ?? '',
      role: _role ?? '',
    );
  }

  Future<void> _openDetail(UserModel user) async {
    final shouldRefresh = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminUserDetail,
      arguments: {'userId': user.id},
    );

    if (shouldRefresh == true && mounted) {
      await context.read<AdminUserProvider>().loadUsers();
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
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: Consumer<AdminUserProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => provider.loadUsers(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _UserFilters(
                  searchController: _searchController,
                  status: _status,
                  role: _role,
                  isLoading: provider.isLoading,
                  onStatusChanged: (value) {
                    setState(() => _status = _emptyToNull(value));
                    _applyFilters();
                  },
                  onRoleChanged: (value) {
                    setState(() => _role = _emptyToNull(value));
                    _applyFilters();
                  },
                  onSearch: _applyFilters,
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
                    onRetry: () => provider.loadUsers(),
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
                  _PaginationBar(provider: provider),
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
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      searchController.clear();
                      onSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: status ?? '',
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả trạng thái')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                  DropdownMenuItem(value: 'BLOCKED', child: Text('BLOCKED')),
                ],
                onChanged: isLoading ? null : onStatusChanged,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: role ?? '',
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả vai trò')),
                  DropdownMenuItem(value: 'CUSTOMER', child: Text('CUSTOMER')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                  DropdownMenuItem(
                    value: 'PHARMACIST',
                    child: Text('PHARMACIST'),
                  ),
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

  final UserModel user;
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
              children: [
                CircleAvatar(
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
                      Text(_fallback(user.email, 'Chưa có email')),
                    ],
                  ),
                ),
                _StatusChip(status: user.status),
              ],
            ),
            const SizedBox(height: 10),
            Text('Số điện thoại: ${_fallback(user.phone, 'Chưa có')}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.roles.isEmpty
                  ? [const Chip(label: Text('Chưa có vai trò'))]
                  : user.roles.map((role) => Chip(label: Text(role))).toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Chi tiết'),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final normalized = status?.trim().toUpperCase() ?? 'INACTIVE';
    final isActive = normalized == 'ACTIVE';
    final color = normalized == 'BLOCKED'
        ? AppTheme.error
        : isActive
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.provider});

  final AdminUserProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: provider.isLoading || provider.isFirstPage
              ? null
              : provider.previousPage,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Trang trước',
        ),
        Expanded(
          child: Text(
            'Trang ${provider.page + 1}/${provider.totalPages} - ${provider.totalElements} người dùng',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: provider.isLoading || provider.isLastPage
              ? null
              : provider.nextPage,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Trang sau',
        ),
      ],
    );
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
        child: Text('Chưa có người dùng phù hợp.', textAlign: TextAlign.center),
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
