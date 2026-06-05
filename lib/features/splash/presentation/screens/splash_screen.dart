import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authProvider = context.read<AuthProvider>();

    await Future<void>.delayed(const Duration(seconds: 1));
    await authProvider.loadCurrentUser();

    if (!mounted) {
      return;
    }

    final nextRoute = authProvider.isAuthenticated
        ? AppRoutes.authenticatedHomeForUser(authProvider.currentUser)
        : AppRoutes.login;
    Navigator.of(context).pushNamedAndRemoveUntil(nextRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.lightBlue, AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MedicalLogo(),
                  SizedBox(height: 28),
                  Text(
                    'An Tâm Pharma',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mua thuốc an tâm, chăm sóc sức khỏe mỗi ngày',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 72),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                      strokeWidth: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicalLogo extends StatelessWidget {
  const _MedicalLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 86,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          Positioned(
            bottom: 21,
            child: Container(
              width: 64,
              height: 43,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
            ),
          ),
          Container(width: 14, height: 52, color: AppTheme.primaryBlue),
          Container(width: 52, height: 14, color: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}
