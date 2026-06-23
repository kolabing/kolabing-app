import '../environment.dart';

/// API configuration constants.
class ApiConfig {
  ApiConfig._();

  /// The single source of truth for the API base URL.
  ///
  /// Resolution order:
  /// 1. `--dart-define=KOLABING_API_BASE_URL=…` (local backend override), else
  /// 2. the URL for the active build flavor ([Environment.apiBaseUrl]).
  ///
  /// Stays `const` so existing `const String _baseUrl = ApiConfig.baseUrl;`
  /// call-sites keep compiling.
  static const String baseUrl = bool.hasEnvironment('KOLABING_API_BASE_URL')
      ? String.fromEnvironment('KOLABING_API_BASE_URL')
      : Environment.apiBaseUrl;
}
