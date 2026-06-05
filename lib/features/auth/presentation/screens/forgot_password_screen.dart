import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(_usernameController.text);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Mã xác thực đã được gửi nếu tài khoản tồn tại'),
        ),
      );
      Navigator.of(context).pushNamed(AppRoutes.forgotPasswordVerifyOtp);
      return;
    }

    final message = authProvider.errorMessage;
    if (message != null && message.trim().isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _backToLogin() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFF),
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                const _ForgotPasswordIcon(),
                const SizedBox(height: 28),
                const Text(
                  'Quên mật khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.darkBlue,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nhập email hoặc số điện thoại đã đăng ký. Chúng tôi sẽ gửi mã xác thực đến email của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!authProvider.isSendingOtp) {
                        _submit();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email hoặc số điện thoại',
                      hintText: 'Nhập email hoặc số điện thoại',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email hoặc số điện thoại';
                      }

                      return null;
                    },
                  ),
                ),
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    authProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: 'Gửi mã xác thực',
                  isLoading: authProvider.isSendingOtp,
                  onPressed: authProvider.isSendingOtp ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _backToLogin,
                  child: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ForgotPasswordIcon extends StatelessWidget {
  const _ForgotPasswordIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.lightBlue),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_reset_rounded,
          color: AppTheme.primaryBlue,
          size: 58,
        ),
      ),
    );
  }
}
