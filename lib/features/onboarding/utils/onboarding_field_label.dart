import '../../../l10n/app_localizations.dart';
import '../models/onboarding_state.dart';

/// Localized labels for [OnboardingField], used to tell the user which required
/// onboarding field is still missing instead of a generic error.
extension OnboardingFieldLabel on OnboardingField {
  String label(AppLocalizations l10n) {
    switch (this) {
      case OnboardingField.name:
        return l10n.onboardingFieldName;
      case OnboardingField.businessCategory:
        return l10n.onboardingFieldBusinessCategory;
      case OnboardingField.venueType:
        return l10n.onboardingFieldVenueType;
      case OnboardingField.venueCapacity:
        return l10n.onboardingFieldVenueCapacity;
      case OnboardingField.venuePhotos:
        return l10n.onboardingFieldVenuePhotos;
      case OnboardingField.businessAddress:
        return l10n.onboardingFieldBusinessAddress;
      case OnboardingField.targetCities:
        return l10n.onboardingFieldTargetCities;
      case OnboardingField.communityType:
        return l10n.onboardingFieldCommunityType;
      case OnboardingField.communityCity:
        return l10n.onboardingFieldCommunityCity;
    }
  }
}

/// Localized "Please complete: a, b" message for a list of missing fields.
/// Returns null when nothing is missing.
String? missingFieldsMessage(
  List<OnboardingField> fields,
  AppLocalizations l10n,
) {
  if (fields.isEmpty) return null;
  final names = fields.map((f) => f.label(l10n)).join(', ');
  return l10n.onboardingCompleteMissingFields(names);
}
