/// Kolabing's published contact address for user-facing enquiries.
///
/// `api_integration_documentations/docs/MOBILE_APP_INTEGRATION_GUIDE.md`
/// ("Support & Resources") documents `support@kolabing.com`, but the product
/// owner has decided that user-facing contact flows (e.g. Event Creator access
/// requests) go to `info@kolabing.com` instead — that decision overrides the
/// doc. It is a public contact address — safe to show to users — and is
/// intentionally literal, like the other external links in `LegalLinks` (it is
/// not an API host, so it does not belong in `Environment`).
class KolabingSupport {
  const KolabingSupport._();

  /// Public contact inbox.
  static const String email = 'info@kolabing.com';
}
