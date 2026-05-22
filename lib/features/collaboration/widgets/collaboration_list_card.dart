import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/collaboration.dart';
import '../providers/collaborations_list_provider.dart';

/// A tappable card for a single collaboration on the "My Kolabs" screen.
///
/// Shows the partner avatar + name, the opportunity title (when present), the
/// scheduled date, and a status badge. Tapping opens `/collaboration/:id`.
/// Mirrors the dashboard's `UpcomingCollaborationCard` style.
class CollaborationListCard extends StatelessWidget {
  const CollaborationListCard({super.key, required this.item, this.onTap});

  final CollaborationListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
          ),
        ),
        child: Row(
          children: [
            _PartnerAvatar(item: item),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.partnerName,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.opportunityTitle != null &&
                      item.opportunityTitle!.isNotEmpty) ...[
                    const SizedBox(height: KolabingSpacing.xxxs),
                    Text(
                      item.opportunityTitle!,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: KolabingColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.scheduledDate != null) ...[
                    const SizedBox(height: KolabingSpacing.xs),
                    _DateChip(
                      dateText: _formatDate(item.scheduledDate!),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            _StatusBadge(status: item.status),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.item});

  final CollaborationListItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.partnerAvatarUrl;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: KolabingColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        image: (url != null && url.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: (url == null || url.isEmpty)
          ? Text(
              item.partnerInitial,
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: KolabingColors.onPrimary,
              ),
            )
          : null,
    );
  }
}

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
            ? KolabingColors.darkBorder
            : KolabingColors.surfaceVariant,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CollaborationStatus status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == CollaborationStatus.completed;
    final color = isCompleted ? KolabingColors.success : KolabingColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: KolabingRadius.borderRadiusXs,
      ),
      child: Text(
        status.label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isCompleted ? const Color(0xFF155724) : color,
        ),
      ),
    );
  }
}
