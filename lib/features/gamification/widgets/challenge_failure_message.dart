import '../../../l10n/app_localizations.dart';
import '../services/challenge_service.dart';

/// Localized copy for a refused challenge (#150, #152).
///
/// Shared rather than duplicated because two screens now start challenges — the
/// peer sheet and, since the flow reversed, the scanner itself — and a refusal
/// that reads differently depending on where you were standing is worse than no
/// message at all.
///
/// The default is deliberately the generic one: a backend that predates the
/// machine-readable reasons still lands here, and says less rather than nothing.
String challengeFailureMessage(ChallengeFailure? kind, AppLocalizations l10n) =>
    switch (kind) {
      ChallengeFailure.bothMustCheckIn => l10n.peerInitiateBothCheckedIn,
      ChallengeFailure.alreadyPending => l10n.peerInitiateAlreadyPending,
      ChallengeFailure.alreadyCompleted => l10n.peerInitiateAlreadyCompleted,
      ChallengeFailure.needsNewPerson => l10n.peerInitiateNeedsNewPerson,
      ChallengeFailure.eventLimitReached => l10n.peerInitiateEventLimit,
      _ => l10n.peerInitiateFailed,
    };
