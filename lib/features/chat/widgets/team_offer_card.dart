import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/kolabing_team_offer.dart';

/// The offer card inside a Kolabing team message (SERR-658): what the offer is,
/// who gets what, and Accept / Not now while it is still open.
///
/// Pure view. [onAccept] / [onDecline] are the caller's; [busy] disables both
/// while a request is in flight so a double tap cannot answer twice.
class TeamOfferCard extends StatelessWidget {
  const TeamOfferCard({
    required this.offer,
    required this.onAccept,
    required this.onDecline,
    this.busy = false,
    super.key,
  });

  final KolabingTeamOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final lines = <String>[
      if (offer.venueName != null && offer.venueName!.trim().isNotEmpty)
        offer.venueName!.trim(),
      if (offer.communityLabel != null && offer.communityLabel!.isNotEmpty)
        l10n.teamOfferWithCommunity(offer.communityLabel!),
      if (offer.proposedDate != null)
        l10n.teamOfferDate(
          DateFormat.yMMMd(locale).format(offer.proposedDate!),
        ),
      if (offer.whatBusinessGets != null && offer.whatBusinessGets!.isNotEmpty)
        l10n.teamOfferBusinessGets(offer.whatBusinessGets!),
      if (offer.whatCommunityGets != null &&
          offer.whatCommunityGets!.isNotEmpty)
        l10n.teamOfferCommunityGets(offer.whatCommunityGets!),
    ];

    return Container(
      key: const ValueKey('team-offer-card'),
      margin: const EdgeInsets.only(top: KolabingSpacing.xs),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 16,
                color: context.colors.primary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  offer.title,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: KolabingSpacing.xxs),
              child: Text(
                line,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: KolabingSpacing.sm),
          if (offer.canRespond)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('team-offer-accept'),
                    onPressed: busy ? null : onAccept,
                    child: Text(l10n.teamOfferAccept),
                  ),
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('team-offer-decline'),
                    onPressed: busy ? null : onDecline,
                    child: Text(l10n.teamOfferNotNow),
                  ),
                ),
              ],
            )
          else
            Chip(
              key: const ValueKey('team-offer-status'),
              label: Text(
                offer.isAccepted
                    ? l10n.teamOfferAccepted
                    : l10n.teamOfferDeclined,
              ),
            ),
        ],
      ),
    );
  }
}
