import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../../../widgets/verified_tick.dart';
import '../models/dashboard_model.dart';

/// A card widget displaying an upcoming collaboration item.
///
/// Shows partner avatar, partner name, opportunity title, date, and status badge.
class UpcomingCollaborationCard extends StatelessWidget {
  const UpcomingCollaborationCard({
    super.key,
    required this.collaboration,
    this.onTap,
  });

  final UpcomingCollaboration collaboration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.darkSurface,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(color: context.colors.darkBorder),
          ),
          child: _content(context, isDark),
        ),
      );
    }

    return CompactListCard(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      onTap: onTap,
      child: _content(context, isDark),
    );
  }

  Widget _content(BuildContext context, bool isDark) {
    return Row(
          children: [
            // Partner avatar
            _PartnerAvatar(partner: collaboration.partner),
            const SizedBox(width: KolabingSpacing.sm),

            // Details column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner name (+ verified tick when verified)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          collaboration.partner.name ?? 'Unknown Partner',
                          style: KolabingTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? context.colors.textOnDark
                                  : context.colors.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (collaboration.partner.isVerified) ...[
                        const SizedBox(width: KolabingSpacing.xxs),
                        const VerifiedTick(isVerified: true, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: KolabingSpacing.xxxs),

                  // Opportunity title
                  Text(
                    collaboration.opportunity.title,
                    style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KolabingSpacing.xs),

                  // Date chip
                  _DateChip(
                    dateText: collaboration.dateDisplay,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),

            // Status badge
            _StatusBadge(status: collaboration.status),
          ],
        );
  }
}

/// Circle avatar showing the partner's initial letter
class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.partner});

  final UpcomingPartnerInfo partner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        partner.initial,
        style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.onPrimary),
      ),
    );
  }
}

/// Small chip showing the scheduled date
class _DateChip extends StatelessWidget {
  const _DateChip({required this.dateText, this.isDark = false});

  final String dateText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.darkBorder
            : context.colors.surfaceVariant,
        borderRadius: KolabingRadius.borderRadiusXs,
      ),
      child: Text(
        dateText,
        style: KolabingTextStyles.labelSmall.copyWith(color: context.colors.onSurfaceVariant),
      ),
    );
  }
}

/// Status badge (SCHEDULED or ACTIVE)
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final UpcomingCollaborationStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == UpcomingCollaborationStatus.active;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? context.colors.info.withValues(alpha: 0.1)
            : context.colors.success.withValues(alpha: 0.1),
        borderRadius: KolabingRadius.borderRadiusXs,
      ),
      child: Text(
        status.displayName,
        style: KolabingTextStyles.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? context.colors.info : context.colors.activeText, letterSpacing: 0.5),
      ),
    );
  }
}
