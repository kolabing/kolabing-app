import 'package:flutter/material.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../models/public_profile.dart';

/// Summary of a profile's reputation — average rating, review count, unique
/// partners, and completed Kolabs. Shared by the public profile and the
/// business owner's own profile so both surfaces stay identical.
///
/// Shows an [EmptyStateCard] when there are no reviews yet. Individual stats
/// hide themselves when their count is zero (noise on a fresh profile).
class ReputationSummaryCard extends StatelessWidget {
  const ReputationSummaryCard({
    required this.reputation,
    this.completedKolabsCount,
    super.key,
  });

  final Reputation? reputation;
  final int? completedKolabsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rep = reputation;

    if (rep == null || !rep.hasReviews) {
      return EmptyStateCard(
        icon: Icons.star_rounded,
        title: l10n.publicProfileReputationEmptyTitle,
        message: l10n.publicProfileReputationEmptyBody,
      );
    }

    final completed = completedKolabsCount ?? 0;

    return PrimaryContentCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 22, color: context.colors.primary),
              const SizedBox(width: KolabingSpacing.xxs),
              Text(
                rep.averageRating?.toStringAsFixed(1) ?? '—',
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
          Flexible(
            child: _ReputationStat(
              label: l10n.publicProfileReputationReviewsCount(rep.reviewCount),
            ),
          ),
          // Hide the partner count entirely when there are none — "0 partners"
          // is noise on a fresh profile.
          if (rep.uniquePartnerCount > 0)
            Flexible(
              child: _ReputationStat(
                label: l10n.publicProfileReputationPartnersCount(
                  rep.uniquePartnerCount,
                ),
              ),
            ),
          // Completed Kolabs — same hide-when-zero rule as partners.
          if (completed > 0)
            Flexible(
              child: _ReputationStat(
                label: l10n.reputationCompletedKolabsCount(completed),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReputationStat extends StatelessWidget {
  const _ReputationStat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    overflow: TextOverflow.ellipsis,
    style: KolabingTextStyles.bodySmall.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
  );
}
