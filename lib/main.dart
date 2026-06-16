import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/routes.dart';
import 'config/theme/theme.dart';
import 'features/settings/providers/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/settings/services/locale_service.dart';
import 'l10n/app_localizations.dart';
import 'services/analytics/analytics_service.dart';
import 'services/global_network_banner_service.dart';
import 'services/notification_service.dart';
import 'services/one_signal_service.dart';

/// Application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await Firebase.initializeApp();

  // Initialize OneSignal alongside FCM so custom push subscriptions exist
  // as soon as the app launches.
  await OneSignalService.instance.initialize();

  // Crashlytics: catch all Flutter framework errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: catch all async/platform errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Replace Flutter's default ErrorWidget — the blank grey box that filled the
  // dashboard whenever a child widget threw — with a graceful, neutral fallback,
  // and record the failure to Crashlytics so the underlying throw is captured.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
    return const _AppErrorFallback();
  };

  // Initialize PostHog product analytics (curated events only — no autocapture
  // or session replay). Fail-safe: an init fault never blocks app launch.
  await AnalyticsService.instance.init();

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
  runApp(const ProviderScope(child: KolabingApp()));
}

/// Neutral fallback shown in place of a widget that threw during build, instead
/// of Flutter's default blank grey box. Kept self-contained (no theme/provider
/// dependencies) so it renders even when the surrounding subtree is broken.
class _AppErrorFallback extends StatelessWidget {
  const _AppErrorFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF7F8FA),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 36, color: Color(0xFF8A8A8A)),
              SizedBox(height: 12),
              Text(
                'Something went wrong here.\nPull to refresh or try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main application widget
class KolabingApp extends ConsumerWidget {
  const KolabingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Null locale = follow the device language (resolved against
    // supportedLocales). A pinned locale comes from the in-app picker.
    final locale = ref.watch(localeProvider.select((s) => s.locale));
    final themeMode = ref.watch(themeProvider.select((s) => s.themeMode));

    return MaterialApp.router(
      title: 'Kolabing',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: globalScaffoldMessengerKey,
      theme: KolabingTheme.lightTheme,
      darkTheme: KolabingTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: LocaleService.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: kolabingRouter,
      builder: (context, child) =>
          _AuthSessionRedirector(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _AuthSessionRedirector extends ConsumerStatefulWidget {
  const _AuthSessionRedirector({required this.child});

  final Widget child;

  @override
  ConsumerState<_AuthSessionRedirector> createState() =>
      _AuthSessionRedirectorState();
}

class _AuthSessionRedirectorState
    extends ConsumerState<_AuthSessionRedirector> {
  static const Set<String> _publicPaths = <String>{
    KolabingRoutes.splash,
    KolabingRoutes.welcome,
    KolabingRoutes.login,
    KolabingRoutes.userTypeSelection,
    KolabingRoutes.attendeeRegister,
    KolabingRoutes.forgotPassword,
    KolabingRoutes.resetPassword,
  };

  bool _hadAuthenticatedSession = false;

  /// Routes from which a transient "unauthenticated" blip must NOT bounce the
  /// user to login: the public auth screens, plus the onboarding flow and the
  /// permissions step. During onboarding completion the auth state can flip
  /// briefly (token write + checkAuthStatus); without this, the user landed on
  /// the "Welcome back" login screen right after finishing onboarding.
  bool _isExemptFromLoginBounce(String path) =>
      _publicPaths.contains(path) ||
      path.startsWith(KolabingRoutes.onboarding) ||
      path == KolabingRoutes.permissions;

  @override
  void initState() {
    super.initState();
    _hadAuthenticatedSession = ref.read(authProvider).isAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _hadAuthenticatedSession = true;
        return;
      }

      if (next.status == AuthStatus.loading) {
        return;
      }

      final lostActiveSession =
          _hadAuthenticatedSession ||
          (previous?.isAuthenticated ?? false) ||
          (previous?.status == AuthStatus.loading && previous?.user != null);
      if (!lostActiveSession) {
        return;
      }

      _hadAuthenticatedSession = false;

      final currentPath =
          kolabingRouter.routeInformationProvider.value.uri.path;
      if (_isExemptFromLoginBounce(currentPath)) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final activePath =
            kolabingRouter.routeInformationProvider.value.uri.path;
        if (_isExemptFromLoginBounce(activePath)) {
          return;
        }
        kolabingRouter.go(KolabingRoutes.login);
      });
    });

    return widget.child;
  }
}
