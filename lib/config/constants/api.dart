/// API configuration constants
class ApiConfig {
  ApiConfig._();

  /// The single source of truth for the API base URL. Defaults to production;
  /// override at build/run time to point at a local backend, e.g.
  /// `flutter run --dart-define=KOLABING_API_BASE_URL=http://127.0.0.1:8000/api/v1`.
  /// (For local http on iOS, an ATS exception is required — see Info.plist.)
  static const String baseUrl = String.fromEnvironment(
    'KOLABING_API_BASE_URL',
    defaultValue: 'https://kolabing.com/api/v1',
  );
}
