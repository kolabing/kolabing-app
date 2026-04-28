import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/event.dart';

/// Compact event card for horizontal list display
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.width = 180,
  });

  final Event event;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        decoration: BoxDecoration(
          borderRadius: KolabingRadius.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: KolabingRadius.borderRadiusLg,
          child: Stack(
            children: [
              // Cover image
              Positioned.fill(
                child: event.coverPhotoUrl != null
                    ? Image.network(
                        event.coverPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // Date badge (top right)
              Positioned(
                top: KolabingSpacing.sm,
                right: KolabingSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: KolabingRadius.borderRadiusSm,
                  ),
                  child: Text(
                    event.formattedDate,
                    style: KolabingTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),

              // Photo count badge (top left, if multiple photos)
              if (event.photos.length > 1)
                Positioned(
                  top: KolabingSpacing.sm,
                  left: KolabingSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: KolabingRadius.borderRadiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.image,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${event.photos.length}',
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (event.videos.isNotEmpty)
                Positioned(
                  top: event.photos.length > 1 ? 44 : KolabingSpacing.sm,
                  left: KolabingSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: KolabingRadius.borderRadiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.playCircle,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${event.videos.length}',
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Content (bottom)
              Positioned(
                left: KolabingSpacing.sm,
                right: KolabingSpacing.sm,
                bottom: KolabingSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Event name
                    Text(
                      event.name,
                      style: KolabingTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Partner row
                    Row(
                      children: [
                        // Partner avatar
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: event.partner.profilePhoto != null
                                ? Image.network(
                                    event.partner.profilePhoto!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildPartnerPlaceholder(),
                                  )
                                : _buildPartnerPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Partner name
                        Expanded(
                          child: Text(
                            event.partner.name,
                            style: KolabingTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Attendee count
                    Row(
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.formattedAttendeeCount} attendees',
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    color: KolabingColors.surfaceVariant,
    child: const Center(
      child: Icon(
        LucideIcons.image,
        size: 32,
        color: KolabingColors.textTertiary,
      ),
    ),
  );

  Widget _buildPartnerPlaceholder() => Container(
    color: KolabingColors.primary,
    child: Center(
      child: Text(
        event.partner.name.isNotEmpty ? event.partner.name[0] : '?',
        style: const TextStyle(
          color: KolabingColors.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
