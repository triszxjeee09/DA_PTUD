import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _showTermsError = !_acceptedTerms;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_acceptedTerms) {
      if (!_acceptedTerms) {
        _showSnackBar('Vui lòng đồng ý với điều khoản sử dụng');
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      return;
    }

    final message = authProvider.errorMessage;
    if (message != null && message.isNotEmpty) {
      _showSnackBar(message);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        top: false,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const _RegisterHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LabeledField(
                          label: 'Họ và tên',
                          child: TextFormField(
                            controller: _fullNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Nhập họ và tên của bạn',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ và tên';
                              }

                              return null;
                            },
                          ),
                        ),
                        _LabeledField(
                          label: 'Số điện thoại',
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Nhập số điện thoại',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }

                              return null;
                            },
                          ),
                        ),
                        _LabeledField(
                          label: 'Email',
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Nhập địa chỉ email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: _validateEmail,
                          ),
                        ),
                        _LabeledField(
                          label: 'Mật khẩu',
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Tạo mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                        ),
                        _LabeledField(
                          label: 'Xác nhận mật khẩu',
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!authProvider.isLoading) {
                                _submit();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Nhập lại mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: _validateConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _TermsCheckbox(
                          value: _acceptedTerms,
                          hasError: _showTermsError,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                              _showTermsError = false;
                            });
                          },
                        ),
                        if (_showTermsError) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Vui lòng đồng ý với điều khoản sử dụng',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (authProvider.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            authProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _submit,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.6,
                                  ),
                                )
                              : const Text('Đăng ký'),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Đã có tài khoản? ',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.login);
                              },
                              child: const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Vui lòng nhập email';
    }

    final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!isValid) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    if (value.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }

    if (value != _passwordController.text) {
      return 'Xác nhận mật khẩu không khớp';
    }

    return null;
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top + 8,
        24,
        32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const _HeaderLogo(),
          const SizedBox(height: 24),
          const Text(
            'Tạo tài khoản',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Đăng ký để mua thuốc, theo dõi đơn hàng và nhận tư vấn từ dược sĩ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFBBD7FF),
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            bottom: 25,
            child: Container(
              width: 40,
              height: 25,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
          Container(width: 8, height: 32, color: AppTheme.primaryBlue),
          Container(width: 32, height: 8, color: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  final bool value;
  final bool hasError;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            side: BorderSide(
              color: hasError ? AppTheme.error : const Color(0xFFC3CAD8),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Tôi đồng ý với ',
              children: [
                TextSpan(
                  text: 'điều khoản sử dụng',
                  style: TextStyle(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
