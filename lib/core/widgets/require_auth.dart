import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../features/auth/providers/auth_provider.dart';

class RequireAuth extends StatelessWidget {
  const RequireAuth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    if (isAuthenticated) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppTheme.primaryBlue,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Vui lòng đăng nhập để sử dụng chức năng này',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.login);
                  },
                  child: const Text('Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
