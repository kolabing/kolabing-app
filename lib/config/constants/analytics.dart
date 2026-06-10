/// PostHog product-analytics configuration.
///
/// The project API key (`phc_...`) is a *write-only, client-side* key — it is
/// safe to ship in the app binary (it cannot read data, only ingest events).
/// It is the single source of truth for analytics wiring, mirroring how
/// [ApiConfig.baseUrl] is the single source for the REST base URL.
///
/// Capture is **curated**: the mobile SDK does not autocapture taps/screens
/// unless wrapped in `PostHogWidget`/`PostHogObserver` (we don't), session
/// replay is off, and `personProfiles` is `identifiedOnly`. We fire a small,
/// hand-picked set of business-critical events (see `AnalyticsEvents`).
class AnalyticsConfig {
  const AnalyticsConfig._();

  /// PostHog project API key (EU cloud, project "Default project" / 195047).
  static const String apiKey = 'phc_zAYyMCY78gWCrTFepwk2fXXhpXBYmjV2w67hV54u67wK';

  /// EU ingestion host. PostHog cloud region is `eu.posthog.com`; the SDK
  /// ingestion endpoint for that region is `https://eu.i.posthog.com`.
  static const String host = 'https://eu.i.posthog.com';
}
