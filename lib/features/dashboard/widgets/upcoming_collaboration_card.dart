import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: KolabingColors.border),
        ),
        child: Row(
          children: [
            // Partner avatar
            _PartnerAvatar(partner: collaboration.partner),
            const SizedBox(width: KolabingSpacing.sm),

            // Details column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner name
                  Text(
                    collaboration.partner.name ?? 'Unknown Partner',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KolabingSpacing.xxxs),

                  // Opportunity title
                  Text(
                    collaboration.opportunity.title,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: KolabingColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KolabingSpacing.xs),

                  // Date chip
                  _DateChip(dateText: collaboration.dateDisplay),
                ],
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),

            // Status badge
            _StatusBadge(status: collaboration.status),
          ],
        ),
      ),
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
        color: KolabingColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        partner.initial,
        style: GoogleFonts.rubik(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: KolabingColors.onPrimary,
        ),
      ),
    );
  }
}

/// Small chip showing the scheduled date
class _DateChip extends StatelessWidget {
  const _DateChip({required this.dateText});

  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceVariant,
        borderRadius: KolabingRadius.borderRadiusXs,
      ),
      child: Text(
        dateText,
        style: GoogleFonts.openSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: KolabingColors.textSecondary,
        ),
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
            ? KolabingColors.info.withValues(alpha: 0.1)
            : KolabingColors.success.withValues(alpha: 0.1),
        borderRadius: KolabingRadius.borderRadiusXs,
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isActive ? KolabingColors.info : const Color(0xFF155724),
        ),
      ),
    );
  }
}
