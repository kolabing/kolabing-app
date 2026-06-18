import 'package:flutter/services.dart' show appFlavor;

/// The two shipped environments. Selected by the Flutter build flavor
/// (`--flavor dev|prod`); a flavorless `flutter run` is treated as [dev].
enum AppEnvironment { dev, prod }

/// Single source of truth for environment-dependent hosts.
///
/// [current] is a compile-time constant derived from Flutter's `appFlavor`,
/// so every value below stays `const` (keeps `ApiConfig.baseUrl` const).
class Environment {
  Environment._();

  static const String _devBase =
      'https://kolabing-v2-development-uhzrzd.laravel.cloud';
  static const String _prodBase = 'https://kolabing.com';

  /// Resolved once from the build flavor. Unknown / absent flavor => dev.
  static const AppEnvironment current = appFlavor == 'prod'
      ? AppEnvironment.prod
      : AppEnvironment.dev;

  static const bool isProd = current == AppEnvironment.prod;

  /// REST base URL (`…/api/v1`).
  static const String apiBaseUrl = isProd
      ? '$_prodBase/api/v1'
      : '$_devBase/api/v1';

  /// Laravel broadcasting auth route (app-root, not under /api/v1).
  static const String broadcastAuth = isProd
      ? '$_prodBase/broadcasting/auth'
      : '$_devBase/broadcasting/auth';

  /// Reverb WebSocket host. Kept on the prod host until a dev Reverb daemon
  /// exists; realtime is gated off on an empty app key regardless.
  static const String reverbHost = 'ws.kolabing.com';

  /// Host for user-facing share / QR deep links (no scheme).
  static const String shareHost = isProd
      ? 'kolabing.com'
      : 'kolabing-v2-development-uhzrzd.laravel.cloud';

  /// Sentry `environment` tag.
  static const String sentryEnvironment = isProd ? 'production' : 'development';

  /// Human label (e.g. for diagnostics).
  static const String label = isProd ? 'Kolabing' : 'Kolabing Dev';

  // --- Pure, testable mirrors of the const logic above. ---
  // Keep [resolveFlavor]/[apiBaseUrlFor] in sync with [current]/[apiBaseUrl];
  // the const fields can't call methods, so the one-liners are duplicated.

  /// Maps a raw flavor string to an [AppEnvironment]. Anything other than
  /// `'prod'` is dev.
  static AppEnvironment resolveFlavor(String? flavor) =>
      flavor == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;

  static String apiBaseUrlFor(AppEnvironment env) =>
      env == AppEnvironment.prod ? '$_prodBase/api/v1' : '$_devBase/api/v1';
}
