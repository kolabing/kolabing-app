import 'package:flutter/foundation.dart' show kReleaseMode;

/// The two shipped environments. Selected at build time with
/// `--dart-define=APP_ENV=dev|prod`; with no define, release builds are [prod]
/// and debug/profile builds are [dev].
enum AppEnvironment { dev, prod }

/// Single source of truth for environment-dependent hosts.
///
/// [current] is a compile-time constant, so every value below stays `const`
/// (keeps `ApiConfig.baseUrl` const). One `APP_ENV` define flips the REST URL,
/// realtime/broadcast host, share host, Sentry environment and PostHog tag
/// together — they can never drift out of sync.
class Environment {
  Environment._();

  static const String _devBase =
      'https://kolabing-v2-development-uhzrzd.laravel.cloud';
  static const String _prodBase = 'https://kolabing.com';

  static const String _envDefine = String.fromEnvironment('APP_ENV');

  /// The active environment, resolved at compile time.
  ///
  /// Resolution order:
  /// 1. `--dart-define=APP_ENV=dev|prod` (what build scripts / CI pass), else
  /// 2. a safe default by build mode: **prod in release, dev in debug/profile**
  ///    — so a bare `flutter build ipa` ships prod, while `flutter run` and
  ///    tests use dev.
  static const AppEnvironment current = _envDefine == 'prod'
      ? AppEnvironment.prod
      : _envDefine == 'dev'
      ? AppEnvironment.dev
      : (kReleaseMode ? AppEnvironment.prod : AppEnvironment.dev);

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
  // Keep [resolveEnv]/[apiBaseUrlFor] in sync with [current]/[apiBaseUrl];
  // the const fields can't call methods, so the one-liners are duplicated.

  /// Pure mirror of [current]'s resolution logic, for testing. An explicit
  /// `'prod'`/`'dev'` define wins; otherwise [isRelease] decides (prod when
  /// releasing, dev otherwise).
  static AppEnvironment resolveEnv(
    String envDefine, {
    required bool isRelease,
  }) => envDefine == 'prod'
      ? AppEnvironment.prod
      : envDefine == 'dev'
      ? AppEnvironment.dev
      : (isRelease ? AppEnvironment.prod : AppEnvironment.dev);

  static String apiBaseUrlFor(AppEnvironment env) =>
      env == AppEnvironment.prod ? '$_prodBase/api/v1' : '$_devBase/api/v1';
}
