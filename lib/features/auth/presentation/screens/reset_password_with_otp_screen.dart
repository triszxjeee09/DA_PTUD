import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordWithOtpScreen extends StatefulWidget {
  const ResetPasswordWithOtpScreen({super.key, required this.otpCode});

  final String otpCode;

  @override
  State<ResetPasswordWithOtpScreen> createState() =>
      _ResetPasswordWithOtpScreenState();
}

class _ResetPasswordWithOtpScreenState
    extends State<ResetPasswordWithOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      if (authProvider.forgotPasswordUsername == null ||
          widget.otpCode.trim().isEmpty) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.forgotPassword,
          (route) => route.settings.name == AppRoutes.login,
        );
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.forgotPasswordUsername == null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.forgotPassword,
        (route) => route.settings.name == AppRoutes.login,
      );
      return;
    }

    final success = await authProvider.resetPasswordWithOtp(
      otpCode: widget.otpCode,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      await _showSuccessDialog();
      return;
    }

    final message = authProvider.errorMessage;
    if (message != null && message.trim().isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đặt lại mật khẩu thành công'),
          content: const Text('Bạn có thể đăng nhập bằng mật khẩu mới.'),
          actions: [
            AppPrimaryButton(
              label: 'Đăng nhập ngay',
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFF),
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text(
          'Tạo mật khẩu mới',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const _ResetPasswordIcon(),
            const SizedBox(height: 28),
            const Text(
              'Tạo mật khẩu mới',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vui lòng tạo mật khẩu mới cho tài khoản của bạn.',
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
              child: Column(
                children: [
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      hintText: 'Nhập mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscureNewPassword
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) {
                        return 'Vui lòng nhập mật khẩu mới';
                      }

                      if (password.length < 6) {
                        return 'Mật khẩu mới tối thiểu 6 ký tự';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!authProvider.isResettingPassword) {
                        _submit();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      hintText: 'Nhập lại mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final confirmPassword = value ?? '';
                      if (confirmPassword.isEmpty) {
                        return 'Vui lòng nhập xác nhận mật khẩu';
                      }

                      if (confirmPassword != _newPasswordController.text) {
                        return 'Xác nhận mật khẩu phải trùng mật khẩu mới';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AppPrimaryButton(
              label: 'Đặt lại mật khẩu',
              isLoading: authProvider.isResettingPassword,
              onPressed: authProvider.isResettingPassword ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetPasswordIcon extends StatelessWidget {
  const _ResetPasswordIcon();

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
