import '../../l10n/app_localizations.dart';
import 'models/opportunity.dart';

/// Localized labels for opportunity enums. Kept out of the model so the data
/// layer stays free of `BuildContext`/l10n dependencies.
extension VenueModeL10n on VenueMode {
  /// Localized display label for this venue mode (en/es/ca).
  String label(AppLocalizations l10n) => switch (this) {
    VenueMode.businessVenue => l10n.venueModeBusinessVenue,
    VenueMode.communityVenue => l10n.venueModeCommunityVenue,
    VenueMode.noVenue => l10n.venueModeNoVenue,
  };
}
