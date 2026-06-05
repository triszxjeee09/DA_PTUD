import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';

class AppNavigator {
  const AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static bool _isRedirectingToLogin = false;
  static bool _isShowingForbiddenMessage = false;

  static void goToLoginAndClearStack() {
    if (_isRedirectingToLogin) {
      return;
    }

    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;

    if (navigator == null || context == null) {
      debugPrint('Không thể điều hướng đăng nhập: navigator chưa sẵn sàng');
      return;
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == AppRoutes.login || currentRoute == AppRoutes.splash) {
      return;
    }

    _isRedirectingToLogin = true;
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại'),
      ),
    );

    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      _isRedirectingToLogin = false;
    });
  }

  static void showForbiddenMessage() {
    if (_isShowingForbiddenMessage) {
      return;
    }

    _isShowingForbiddenMessage = true;
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Bạn không có quyền thực hiện thao tác này'),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 600), () {
      _isShowingForbiddenMessage = false;
    });
  }
}
