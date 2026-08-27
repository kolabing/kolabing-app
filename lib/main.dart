import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config/constants/sentry.dart';
import 'config/routes/routes.dart';
import 'config/theme/theme.dart';
import 'features/settings/providers/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/widgets/reconsent_gate.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/settings/services/locale_service.dart';
import 'l10n/app_localizations.dart';
import 'services/analytics/analytics_service.dart';
import 'services/global_network_banner_service.dart';
import 'services/notification_service.dart';
import 'services/one_signal_service.dart';

/// Application entry point.
///
/// When a Sentry DSN is configured, the whole app runs inside
/// `SentryFlutter.init` so uncaught errors are captured; otherwise it boots
/// directly (Sentry is a no-op).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SentryConfig.isEnabled) {
    await SentryFlutter.init(_configureSentry, appRunner: _bootstrapAndRunApp);
  } else {
    await _bootstrapAndRunApp();
  }
}

void _configureSentry(SentryFlutterOptions options) {
  options
    ..dsn = SentryConfig.dsn
    ..environment = SentryConfig.environment
    ..tracesSampleRate = SentryConfig.tracesSampleRate
    ..debug = kDebugMode
    // We never attach default PII; user context is added explicitly elsewhere.
    ..sendDefaultPii = false;
}

Future<void> _bootstrapAndRunApp() async {
  // Firebase initialization
  await Firebase.initializeApp();

  // Initialize OneSignal alongside FCM so custom push subscriptions exist
  // as soon as the app launches.
  await OneSignalService.instance.initialize();

  _configureErrorReporting();

  // Initialize PostHog product analytics (curated events only — no autocapture
  // or session replay). Fail-safe: an init fault never blocks app launch.
  await AnalyticsService.instance.init();

  // Initialize push notifications
  await NotificationService.instance.initialize();

  // Connect FCM notification taps to GoRouter navigation
  connectNotificationRouter();
  connectDeepLinks();

  // Set preferred orientations (portrait only for mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app with Riverpod
  runApp(const ProviderScope(child: KolabingApp()));
}

/// Wires Flutter/platform errors to Crashlytics and (when enabled) Sentry.
void _configureErrorReporting() {
  // Catch all Flutter framework errors.
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    if (SentryConfig.isEnabled) {
      unawaited(
        Sentry.captureException(details.exception, stackTrace: details.stack),
      );
    }
  };

  // Catch async/platform errors outside the Flutter framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    if (SentryConfig.isEnabled) {
      unawaited(Sentry.captureException(error, stackTrace: stack));
    }
    return true;
  };

  // Replace Flutter's default ErrorWidget — the blank grey box that filled the
  // dashboard whenever a child widget threw — with a graceful, neutral fallback,
  // and record the failure so the underlying throw is captured.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
    if (SentryConfig.isEnabled) {
      unawaited(
        Sentry.captureException(details.exception, stackTrace: details.stack),
      );
    }
    return const _AppErrorFallback();
  };
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

class _AuthSessionRedirectorState extends ConsumerState<_AuthSessionRedirector>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume, re-fetch the user so a Terms/Privacy version bumped while the
    // app was backgrounded surfaces the re-consent gate.
    if (state == AppLifecycleState.resumed &&
        ref.read(authProvider).isAuthenticated) {
      unawaited(ref.read(authProvider.notifier).refreshUser());
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsConsent = ref.watch(
      authProvider.select((s) => s.needsTermsConsent),
    );

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

    return Stack(
      children: [
        widget.child,
        if (needsConsent) const Positioned.fill(child: ReconsentGate()),
      ],
    );
  }
}
