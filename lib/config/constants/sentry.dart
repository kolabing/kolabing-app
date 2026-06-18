import 'package:flutter/foundation.dart';

/// Sentry runtime configuration for the **kolabing-mobile** Flutter project
/// (org `kolabng`, project id `4511585430339664`) — separate from the Laravel
/// backend project.
///
/// The DSN is a *publishable* client key (send-only; it cannot read data), so
/// it ships compiled into the app by default. Any value can still be overridden
/// at build time, e.g.:
///
/// ```sh
/// flutter run --dart-define=SENTRY_DSN=… \
///   --dart-define=SENTRY_ENVIRONMENT=staging \
///   --dart-define=SENTRY_TRACES_SAMPLE_RATE=0.2
/// ```
class SentryConfig {
  SentryConfig._();

  /// Default DSN for the kolabing-mobile project. Override with
  /// `--dart-define=SENTRY_DSN=…` to point a build at another project.
  static const String _defaultDsn =
      'https://d6eff343d5074635b22c4414cc1e7e47@o4511574633938944.ingest.de.sentry.io/4511585430339664';

  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: _defaultDsn,
  );

  /// Tag applied to every event for filtering in the dashboard. Defaults to the
  /// build mode; override per environment via `SENTRY_ENVIRONMENT`.
  static const String environment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );

  /// Fraction (0.0–1.0) of transactions captured for performance monitoring.
  ///
  /// Defaults to 100% in debug (so verification is easy) and a conservative
  /// 20% in release to control quota/cost as traffic grows. Override with
  /// `--dart-define=SENTRY_TRACES_SAMPLE_RATE=…`.
  static double get tracesSampleRate {
    const raw = String.fromEnvironment('SENTRY_TRACES_SAMPLE_RATE');
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      return kReleaseMode ? 0.2 : 1.0;
    }
    if (parsed < 0.0) return 0.0;
    if (parsed > 1.0) return 1.0;
    return parsed;
  }

  /// Sentry is active only when a non-empty DSN is configured.
  static bool get isEnabled => dsn.trim().isNotEmpty;
}
