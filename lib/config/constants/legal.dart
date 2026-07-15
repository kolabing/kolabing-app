/// Canonical links to the published legal agreements (marketing site).
///
/// The app links out to these pages — it does not re-render the legal text
/// in-app. Only Spanish has a localized page; every other device language
/// (including Catalan) falls back to English, per the consent-flow spec.
///
/// These are external marketing-site URLs (distinct from `ApiConfig.baseUrl`),
/// so they are intentionally literal — like other external deep links.
class LegalLinks {
  const LegalLinks._();

  static const String _base = 'https://kolabing.com';

  /// Terms of Service URL for the given device [languageCode] (default: EN).
  static String termsUrl(String? languageCode) =>
      languageCode == 'es' ? '$_base/es/terms' : '$_base/terms';

  /// Privacy Policy URL for the given device [languageCode] (default: EN).
  static String privacyUrl(String? languageCode) =>
      languageCode == 'es' ? '$_base/es/privacy' : '$_base/privacy';
}
