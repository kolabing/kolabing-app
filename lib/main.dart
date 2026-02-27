import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/routes.dart';
import 'config/theme/theme.dart';
import 'services/notification_service.dart';

/// Application entry point
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await Firebase.initializeApp();

  // Initialize push notifications
  await NotificationService.instance.initialize();

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
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // App configuration
      title: 'Kolabing',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: KolabingTheme.lightTheme,
      themeMode: ThemeMode.light,

      // Router configuration
      routerConfig: kolabingRouter,
    );
  }
}
