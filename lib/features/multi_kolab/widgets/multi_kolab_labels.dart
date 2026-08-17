import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/multi_kolab_enums.dart';

/// Product-facing wording for every Multi-Kolab wire enum.
///
/// The backend values (`recruiting`, `positions_filled`,
/// `eligible_account_type`, ...) are never shown to an organizer — this is
/// the single place that maps them to localized copy, so no widget has to
/// know a wire value exists.
extension MultiKolabEventStatusLabel on MultiKolabEventStatus {
  String label(AppLocalizations l10n) => switch (this) {
    MultiKolabEventStatus.draft => l10n.multiKolabEventStatusDraft,
    MultiKolabEventStatus.recruiting => l10n.multiKolabEventStatusRecruiting,
    MultiKolabEventStatus.confirmed => l10n.multiKolabEventStatusConfirmed,
    MultiKolabEventStatus.completed => l10n.multiKolabEventStatusCompleted,
    MultiKolabEventStatus.cancelled => l10n.multiKolabEventStatusCancelled,
    MultiKolabEventStatus.expired => l10n.multiKolabEventStatusExpired,
  };

  /// Terminal statuses admit no further mutation (contract §5).
  bool get isTerminal =>
      this == MultiKolabEventStatus.completed ||
      this == MultiKolabEventStatus.cancelled ||
      this == MultiKolabEventStatus.expired;
}

extension MultiKolabRoleStatusLabel on MultiKolabRoleStatus {
  String label(AppLocalizations l10n) => switch (this) {
    MultiKolabRoleStatus.open => l10n.multiKolabRoleStatusOpen,
    MultiKolabRoleStatus.filled => l10n.multiKolabRoleStatusFilled,
    MultiKolabRoleStatus.closed => l10n.multiKolabRoleStatusClosed,
  };
}

extension MultiKolabApplicationStatusLabel on MultiKolabRoleApplicationStatus {
  String label(AppLocalizations l10n) => switch (this) {
    MultiKolabRoleApplicationStatus.pending =>
      l10n.multiKolabApplicationStatusPending,
    MultiKolabRoleApplicationStatus.shortlisted =>
      l10n.multiKolabApplicationStatusShortlisted,
    MultiKolabRoleApplicationStatus.accepted =>
      l10n.multiKolabApplicationStatusAccepted,
    MultiKolabRoleApplicationStatus.declined =>
      l10n.multiKolabApplicationStatusDeclined,
    MultiKolabRoleApplicationStatus.withdrawn =>
      l10n.multiKolabApplicationStatusWithdrawn,
  };
}

extension MultiKolabEligibilityLabel on MultiKolabEligibleAccountType {
  String label(AppLocalizations l10n) => switch (this) {
    MultiKolabEligibleAccountType.business => l10n.multiKolabEligibilityBusiness,
    MultiKolabEligibleAccountType.community =>
      l10n.multiKolabEligibilityCommunity,
    MultiKolabEligibleAccountType.either => l10n.multiKolabEligibilityEither,
  };

  /// Plain-language explanation of which Explore feed an open role of this
  /// eligibility will appear in — shown in the role editor so the organizer
  /// understands the consequence of the choice.
  String visibilityExplanation(AppLocalizations l10n) => switch (this) {
    MultiKolabEligibleAccountType.business =>
      l10n.multiKolabRoleFormVisibilityBusiness,
    MultiKolabEligibleAccountType.community =>
      l10n.multiKolabRoleFormVisibilityCommunity,
    MultiKolabEligibleAccountType.either =>
      l10n.multiKolabRoleFormVisibilityEither,
  };
}

extension MultiKolabCompensationLabel on MultiKolabCompensationType {
  String label(AppLocalizations l10n) => switch (this) {
    MultiKolabCompensationType.paid => l10n.multiKolabCompensationPaid,
    MultiKolabCompensationType.sponsoredInKind =>
      l10n.multiKolabCompensationSponsoredInKind,
    MultiKolabCompensationType.valueExchange =>
      l10n.multiKolabCompensationValueExchange,
    MultiKolabCompensationType.negotiable =>
      l10n.multiKolabCompensationNegotiable,
  };
}

/// Pastel status pill for Multi-Kolab surfaces.
///
/// Deliberately not [KolabStatusBadge]: that widget resolves its own
/// hardcoded English uppercase label from a raw status string and cannot be
/// localized. This one takes an already-localized [label] and reuses the
/// exact same visual tokens (round pill, tinted background, `labelSmall`
/// 700) so the two are visually indistinguishable.
class MultiKolabStatusChip extends StatelessWidget {
  const MultiKolabStatusChip({
    required this.label,
    required this.tone,
    super.key,
    this.semanticPrefix,
  });

  /// Already-localized text. Never a wire enum value.
  final String label;
  final MultiKolabStatusTone tone;

  /// Optional prefix so a screen reader hears "Status: Recruiting partners"
  /// rather than a bare word — status must never be conveyed by colour alone.
  final String? semanticPrefix;

  factory MultiKolabStatusChip.event(
    MultiKolabEventStatus status,
    AppLocalizations l10n,
  ) {
    return MultiKolabStatusChip(
      label: status.label(l10n),
      tone: switch (status) {
        MultiKolabEventStatus.draft => MultiKolabStatusTone.neutral,
        MultiKolabEventStatus.recruiting => MultiKolabStatusTone.active,
        MultiKolabEventStatus.confirmed => MultiKolabStatusTone.positive,
        MultiKolabEventStatus.completed => MultiKolabStatusTone.done,
        MultiKolabEventStatus.cancelled ||
        MultiKolabEventStatus.expired => MultiKolabStatusTone.negative,
      },
    );
  }

  factory MultiKolabStatusChip.role(
    MultiKolabRoleStatus status,
    AppLocalizations l10n,
  ) {
    return MultiKolabStatusChip(
      label: status.label(l10n),
      tone: switch (status) {
        MultiKolabRoleStatus.open => MultiKolabStatusTone.active,
        MultiKolabRoleStatus.filled => MultiKolabStatusTone.positive,
        MultiKolabRoleStatus.closed => MultiKolabStatusTone.neutral,
      },
    );
  }

  factory MultiKolabStatusChip.application(
    MultiKolabRoleApplicationStatus status,
    AppLocalizations l10n,
  ) {
    return MultiKolabStatusChip(
      label: status.label(l10n),
      tone: switch (status) {
        MultiKolabRoleApplicationStatus.pending => MultiKolabStatusTone.pending,
        MultiKolabRoleApplicationStatus.shortlisted =>
          MultiKolabStatusTone.active,
        MultiKolabRoleApplicationStatus.accepted =>
          MultiKolabStatusTone.positive,
        MultiKolabRoleApplicationStatus.declined =>
          MultiKolabStatusTone.negative,
        MultiKolabRoleApplicationStatus.withdrawn =>
          MultiKolabStatusTone.neutral,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = tone.colors(colors);

    return Semantics(
      label: semanticPrefix == null ? label : '$semanticPrefix: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xxxs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Text(
          label,
          style: KolabingTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

enum MultiKolabStatusTone {
  neutral,
  pending,
  active,
  positive,
  negative,
  done;

  (Color, Color) colors(KolabingColorTokens c) => switch (this) {
    MultiKolabStatusTone.neutral => (c.surfaceVariant, c.muted),
    MultiKolabStatusTone.pending => (c.pendingBg, c.pendingText),
    MultiKolabStatusTone.active => (c.primaryTint, c.amber),
    MultiKolabStatusTone.positive => (c.activeBg, c.activeText),
    MultiKolabStatusTone.negative => (c.errorBg, c.errorText),
    MultiKolabStatusTone.done => (c.completedBg, c.completedText),
  };
}
