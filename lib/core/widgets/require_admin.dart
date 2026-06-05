import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';

class RequireAdmin extends StatelessWidget {
  const RequireAdmin({super.key, required this.child});

  static const String _loginRoute = '/login';
  static const String _homeRoute = '/main';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select<AuthProvider, UserModel?>(
      (provider) => provider.currentUser,
    );

    if (currentUser == null) {
      return _AdminGuardMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Vui lòng đăng nhập để tiếp tục',
        buttonText: 'Đăng nhập',
        onPressed: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(_loginRoute, (route) => false);
        },
      );
    }

    if (!currentUser.isAdmin) {
      return _AdminGuardMessage(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Bạn không có quyền truy cập chức năng quản trị',
        buttonText: 'Về trang chủ',
        onPressed: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(_homeRoute, (route) => false);
        },
      );
    }

    return child;
  }
}

class _AdminGuardMessage extends StatelessWidget {
  const _AdminGuardMessage({
    required this.icon,
    required this.title,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản trị')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.lightBlue,
                  child: Icon(icon, color: AppTheme.primaryBlue, size: 34),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: onPressed, child: Text(buttonText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
