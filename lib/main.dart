import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/routes.dart';
import 'config/theme/theme.dart';
import 'features/settings/providers/theme_provider.dart';

/// Application entry point
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

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
class KolabingApp extends ConsumerWidget {
  const KolabingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      // App configuration
      title: 'Kolabing',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: KolabingTheme.lightTheme,
      darkTheme: KolabingTheme.darkTheme,
      themeMode: themeState.themeMode,

      // Router configuration
      routerConfig: kolabingRouter,

      // Localization (to be configured later)
      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en', 'US'),
      //   Locale('es', 'ES'),
      // ],
    );
  }
}
