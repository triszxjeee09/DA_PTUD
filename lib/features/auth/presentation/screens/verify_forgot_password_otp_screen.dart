import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../providers/auth_provider.dart';

class VerifyForgotPasswordOtpScreen extends StatefulWidget {
  const VerifyForgotPasswordOtpScreen({super.key});

  @override
  State<VerifyForgotPasswordOtpScreen> createState() =>
      _VerifyForgotPasswordOtpScreenState();
}

class _VerifyForgotPasswordOtpScreenState
    extends State<VerifyForgotPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final otpCode = _otpController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyForgotPasswordOtp(otpCode);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushNamed(
        AppRoutes.forgotPasswordResetPassword,
        arguments: {'otpCode': otpCode},
      );
      return;
    }

    _showError(authProvider.errorMessage);
  }

  Future<void> _resendOtp() async {
    final authProvider = context.read<AuthProvider>();
    final username = authProvider.forgotPasswordUsername;
    if (username == null || username.trim().isEmpty) {
      _changeUsername();
      return;
    }

    final success = await authProvider.forgotPassword(username);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Mã xác thực mới đã được gửi')),
        );
      return;
    }

    _showError(authProvider.errorMessage);
  }

  void _changeUsername() {
    context.read<AuthProvider>().clearForgotPasswordState();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.forgotPassword,
      (route) => route.settings.name == AppRoutes.login,
    );
  }

  void _showError(String? message) {
    final text = message?.trim();
    if (text == null || text.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expiresInMinutes = authProvider.otpExpiresInMinutes;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFF),
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text(
          'Nhập mã xác thực',
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
            const _OtpIcon(),
            const SizedBox(height: 28),
            const Text(
              'Nhập mã xác thực',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Mã xác thực đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư đến hoặc thư rác.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            if (expiresInMinutes != null && expiresInMinutes > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Mã có hiệu lực trong $expiresInMinutes phút',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.darkBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onFieldSubmitted: (_) {
                  if (!authProvider.isVerifyingOtp) {
                    _verifyOtp();
                  }
                },
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
                validator: (value) {
                  final otpCode = value?.trim() ?? '';
                  if (otpCode.isEmpty) {
                    return 'Vui lòng nhập mã xác thực';
                  }

                  if (!RegExp(r'^\d{6}$').hasMatch(otpCode)) {
                    return 'Mã xác thực phải gồm 6 chữ số';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 22),
            AppPrimaryButton(
              label: 'Xác thực mã',
              isLoading: authProvider.isVerifyingOtp,
              onPressed: authProvider.isVerifyingOtp ? null : _verifyOtp,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: authProvider.isSendingOtp ? null : _resendOtp,
              child: authProvider.isSendingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text(
                      'Gửi lại mã',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
            TextButton(
              onPressed: _changeUsername,
              child: const Text(
                'Đổi email/số điện thoại',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpIcon extends StatelessWidget {
  const _OtpIcon();

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
          Icons.mark_email_read_outlined,
          color: AppTheme.primaryBlue,
          size: 56,
        ),
      ),
    );
  }
}
