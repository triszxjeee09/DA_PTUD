import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (!(user?.isAdmin ?? false)) {
      return const Scaffold(
        body: Center(child: Text('Bạn không có quyền truy cập khu vực Admin.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản Admin')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _AdminProfileHeader(user: user!),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Chức năng quản trị',
                  subtitle: 'Mở các công cụ quản trị mở rộng',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminMore),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.person_rounded,
                  title: 'Thông tin cá nhân',
                  subtitle: 'Xem thông tin tài khoản quản trị',
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.accountProfile),
                ),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.storefront_rounded,
                  title: 'Về giao diện khách hàng',
                  subtitle: 'Xem ứng dụng như khách hàng',
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
                  },
                ),
                const Divider(height: 1),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  subtitle: 'Thoát khỏi tài khoản hiện tại',
                  isDestructive: true,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminProfileHeader extends StatelessWidget {
  const _AdminProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppTheme.lightBlue,
              backgroundImage: user.avatarUrl?.trim().isNotEmpty == true
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl?.trim().isNotEmpty == true
                  ? null
                  : const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppTheme.primaryBlue,
                      size: 34,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fallback(user.fullName, 'Quản trị viên'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fallback(user.email, 'Chưa có email'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Chip(
                    label: Text('ADMIN'),
                    avatar: Icon(Icons.verified_user_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.primaryBlue;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
