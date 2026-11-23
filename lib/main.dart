import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/firebase/firebase_messaging_config.dart';
import 'core/navigation/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // The Android Google Services plugin supplies options from
    // android/app/google-services.json. Keep Firebase optional so builds
    // without that file still start normally.
    await Firebase.initializeApp();
    await FirebaseMessagingConfig.initialize();
    await FirebaseMessagingConfig.listenNotificationNavigation(

      AppNavigator.navigatorKey,
    );
  } catch (error) {
    debugPrint('Firebase initialize failed; continuing without push: $error');
  }

  runApp(const PharmaApp());
}
