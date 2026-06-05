import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../features/auth/providers/auth_provider.dart';

class NotificationNavigationHandler {
  static const Set<String> _availableRoutes = {
    AppRoutes.login,
    AppRoutes.notifications,
    AppRoutes.orderDetail,
    AppRoutes.prescriptionDetail,
    AppRoutes.applyVoucher,
    AppRoutes.vouchers,
  };

  static void handleMessageNavigation(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint(
          'Không thể điều hướng notification: navigator chưa sẵn sàng',
        );
        return;
      }

      if (!_isAuthenticated(navigatorKey.currentContext)) {
        _pushNamedSafely(navigator, AppRoutes.login);
        return;
      }

      final data = message.data;
      final type = data['type']?.toString().trim().toUpperCase();
      final referenceId = _readReferenceId(data['referenceId']);
      final target = _readTargetRoute(type, referenceId);

      _pushNamedSafely(
        navigator,
        target.routeName,
        arguments: target.arguments,
      );
    } catch (error) {
      debugPrint('Không thể xử lý điều hướng notification: $error');
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        _pushNamedSafely(navigator, AppRoutes.notifications);
      }
    }
  }

  static _NotificationRoute _readTargetRoute(
    String? type,
    String? referenceId,
  ) {
    switch (type) {
      case 'ORDER':
        if (referenceId != null) {
          return _NotificationRoute(
            routeName: AppRoutes.orderDetail,
            arguments: {'orderId': referenceId},
          );
        }
        return const _NotificationRoute(routeName: AppRoutes.notifications);
      case 'PRESCRIPTION':
        if (referenceId != null) {
          return _NotificationRoute(
            routeName: AppRoutes.prescriptionDetail,
            arguments: {'id': referenceId},
          );
        }
        return const _NotificationRoute(routeName: AppRoutes.notifications);
      case 'PROMOTION':
      case 'SYSTEM':
      default:
        return const _NotificationRoute(routeName: AppRoutes.notifications);
    }
  }

  static bool _isAuthenticated(BuildContext? context) {
    if (context == null) {
      return false;
    }

    try {
      return context.read<AuthProvider>().isAuthenticated;
    } catch (error) {
      debugPrint('Không thể đọc trạng thái đăng nhập: $error');
      return false;
    }
  }

  static String? _readReferenceId(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static void _pushNamedSafely(
    NavigatorState navigator,
    String routeName, {
    Object? arguments,
  }) {
    final safeRoute = _availableRoutes.contains(routeName)
        ? routeName
        : AppRoutes.notifications;

    navigator.pushNamed(safeRoute, arguments: arguments);
  }
}

class _NotificationRoute {
  const _NotificationRoute({required this.routeName, this.arguments});

  final String routeName;
  final Object? arguments;
}
