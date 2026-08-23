import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/discovered_event.dart';

/// Card displaying a discovered event
class DiscoveredEventCard extends StatelessWidget {
  const DiscoveredEventCard({super.key, required this.event, this.onTap});

  final DiscoveredEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
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
                color: context.colors.primary.withValues(alpha: 0.1),
                image: event.photos.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(event.photos.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: event.photos.isEmpty
                  ? Icon(
                      LucideIcons.calendar,
                      size: 32,
                      color: context.colors.primary,
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
                          ? context.colors.info.withValues(alpha: 0.1)
                          : context.colors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.isBusiness
                          ? l10n.eventPartnerBusiness
                          : l10n.eventPartnerCommunity,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: event.isBusiness
                            ? context.colors.info
                            : context.colors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Event name
                  Text(
                    event.name,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Host community name · type
                  Text(
                    _hostLine(),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: KolabingColors.onSurfaceVariant,
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
                        color: context.colors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(context, event.eventDate),
                        style: KolabingTextStyles.labelSmall.copyWith(
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Icon(
                        LucideIcons.users,
                        size: 12,
                        color: context.colors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendeeCount}',
                        style: KolabingTextStyles.labelSmall.copyWith(
                          color: context.colors.textTertiary,
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
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: context.colors.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.distanceDisplay,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
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

  /// "Real Run Club · Running" — host community name + humanized
  /// community_type. Falls back to the host name alone when the type is absent.
  String _hostLine() {
    final type = event.communityType;
    if (type != null && type.isNotEmpty) {
      return '${event.hostName} · ${_humanizeSlug(type)}';
    }
    return event.hostName;
  }

  String _humanizeSlug(String slug) => slug
      .split(RegExp('[_-]'))
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return l10n.eventDateToday;
    } else if (diff.inDays == 1) {
      return l10n.eventDateTomorrow;
    } else if (diff.inDays < 7 && diff.inDays > 0) {
      return l10n.eventDateInDays(diff.inDays);
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
