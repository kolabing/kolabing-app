import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/discovered_event.dart';

/// Card displaying a discovered event
class DiscoveredEventCard extends StatelessWidget {
  const DiscoveredEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final DiscoveredEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Event image or placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: KolabingColors.primary.withValues(alpha: 0.1),
                image: event.photos.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(event.photos.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: event.photos.isEmpty
                  ? const Icon(
                      LucideIcons.calendar,
                      size: 32,
                      color: KolabingColors.primary,
                    )
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.md),

            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: event.isBusiness
                          ? KolabingColors.info.withValues(alpha: 0.1)
                          : KolabingColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.isBusiness ? 'Business' : 'Community',
                      style: GoogleFonts.rubik(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: event.isBusiness
                            ? KolabingColors.info
                            : KolabingColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Event name
                  Text(
                    event.name,
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Partner name
                  Text(
                    'by ${event.partnerName}',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Event date and attendees
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: KolabingColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.eventDate),
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Icon(
                        LucideIcons.users,
                        size: 12,
                        color: KolabingColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendeeCount}',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Distance badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: KolabingColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: KolabingColors.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.distanceDisplay,
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays < 7 && diff.inDays > 0) {
      return 'In ${diff.inDays} days';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
