import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import 'notification_navigation_handler.dart';

class FirebaseMessagingConfig {
  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) return;

    try {
      await requestPermission();
      listenForegroundMessages();
    } catch (error) {
      debugPrint('FirebaseMessagingConfig initialize failed: $error');
    }
  }

  static Future<String?> getFcmToken() async {
    if (Firebase.apps.isEmpty) return null;

    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('Get FCM token failed: $error');
      return null;
    }
  }

  static Future<void> requestPermission() async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (error) {
      debugPrint('Request notification permission failed: $error');
    }
  }

  static void listenForegroundMessages() {
    if (Firebase.apps.isEmpty) return;

    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title?.trim();
        final body = notification?.body?.trim();
        debugPrint(
          'Foreground FCM message: title=$title, body=$body',
        );
        if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
          return;
        }
        AppNavigator.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title.isNotEmpty)
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (body != null && body.isNotEmpty) Text(body),
              ],
            ),
          ),
        );
      });
    } catch (error) {
      debugPrint('Listen foreground FCM messages failed: $error');
    }
  }

  static void listenTokenRefresh(void Function(String token) onTokenRefresh) {
    if (Firebase.apps.isEmpty) return;

    try {
      FirebaseMessaging.instance.onTokenRefresh.listen(onTokenRefresh);
    } catch (error) {
      debugPrint('Listen FCM token refresh failed: $error');
    }
  }

  static Future<void> listenNotificationNavigation(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (Firebase.apps.isEmpty) return;

    try {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        NotificationNavigationHandler.handleMessageNavigation(
          message,
          navigatorKey,
        );
      });

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage == null) {
        return;
      }

      // Chờ app dựng xong navigator và splash kiểm tra phiên đăng nhập.
      Future<void>.delayed(const Duration(seconds: 2), () {
        NotificationNavigationHandler.handleMessageNavigation(
          initialMessage,
          navigatorKey,
        );
      });
    } catch (error) {
      debugPrint('Listen notification navigation failed: $error');
    }
  }
}
