import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/routes.dart';
import 'config/theme/theme.dart';
import 'services/notification_service.dart';

/// Application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await Firebase.initializeApp();

  // Crashlytics: catch all Flutter framework errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: catch all async/platform errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize push notifications
  await NotificationService.instance.initialize();

  // Connect FCM notification taps to GoRouter navigation
  connectNotificationRouter();

  // Set preferred orientations (portrait only for mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: KolabingApp(),
    ),
  );
}

/// Main application widget
class KolabingApp extends StatelessWidget {
  const KolabingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Kolabing',
        debugShowCheckedModeBanner: false,
        theme: KolabingTheme.lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: kolabingRouter,
      );
}
