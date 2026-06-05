import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/firebase/firebase_messaging_config.dart';
import 'core/navigation/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Cần chạy flutterfire configure để tạo firebase_options.dart
    await Firebase.initializeApp();
    await FirebaseMessagingConfig.initialize();
    await FirebaseMessagingConfig.listenNotificationNavigation(
      AppNavigator.navigatorKey,
    );
  } catch (error) {
    debugPrint(
      'Firebase initialize failed. Please check Firebase configuration: $error',
    );
  }

  runApp(const PharmaApp());
}
