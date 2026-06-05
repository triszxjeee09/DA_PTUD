import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'notification_navigation_handler.dart';

class FirebaseMessagingConfig {
  static Future<void> initialize() async {
    try {
      await requestPermission();
      listenForegroundMessages();
    } catch (error) {
      debugPrint('FirebaseMessagingConfig initialize failed: $error');
    }
  }

  static Future<String?> getFcmToken() async {
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('Get FCM token failed: $error');
      return null;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (error) {
      debugPrint('Request notification permission failed: $error');
    }
  }

  static void listenForegroundMessages() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        debugPrint(
          'Foreground FCM message: title=${notification?.title}, body=${notification?.body}',
        );
      });
    } catch (error) {
      debugPrint('Listen foreground FCM messages failed: $error');
    }
  }

  static void listenTokenRefresh(void Function(String token) onTokenRefresh) {
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen(onTokenRefresh);
    } catch (error) {
      debugPrint('Listen FCM token refresh failed: $error');
    }
  }

  static Future<void> listenNotificationNavigation(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
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
