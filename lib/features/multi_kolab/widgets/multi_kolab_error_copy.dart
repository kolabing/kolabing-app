import '../../../l10n/app_localizations.dart';

/// Maps a **stable backend error code** to localized copy.
///
/// The one and only translation point for Multi-Kolab organizer errors.
/// Screens must pass the code from `ApiError.stableCode` (contract §10) —
/// never `ApiError.message`, which is human-readable, unlocalized and free
/// to change without notice.
String multiKolabErrorCopy(String? stableCode, AppLocalizations l10n) {
  return switch (stableCode) {
    'not_owner' => l10n.multiKolabErrorNotOwner,
    'invalid_transition' => l10n.multiKolabErrorInvalidTransition,
    'role_capacity_exceeded' => l10n.multiKolabErrorRoleCapacity,
    'role_has_accepted_application' => l10n.multiKolabErrorRoleCapacity,
    'event_creator_required' => l10n.multiKolabEntitlementGateBody,
    _ => l10n.multiKolabErrorGeneric,
  };
}
