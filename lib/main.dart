import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/routes/routes.dart';
import 'config/theme/theme.dart';

/// Supabase configuration
///
/// Replace these placeholder values with your actual Supabase project credentials.
/// For security, consider using environment variables or a config file that is
/// not committed to version control.
const String _supabaseUrl = 'YOUR_SUPABASE_URL';
const String _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

/// Application entry point
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: KolabingApp(),
    ),
  );
}

/// Supabase client accessor
///
/// Use this to access the Supabase client throughout the app.
SupabaseClient get supabase => Supabase.instance.client;

/// Main application widget
class KolabingApp extends ConsumerWidget {
  const KolabingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        // App configuration
        title: 'Kolabing',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: KolabingTheme.lightTheme,
        darkTheme: KolabingTheme.darkTheme,
        themeMode: ThemeMode.light, // Default to light theme

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
