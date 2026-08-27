import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/public_profile.dart';

/// Card widget displaying a past collaboration.
///
/// Shows the collaboration title, partner info, date, and status.
class PastCollaborationCard extends StatelessWidget {
  const PastCollaborationCard({required this.collaboration, super.key});

  final PastCollaboration collaboration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: context.colors.hairline, width: 1),
        boxShadow: [KolabingShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            collaboration.title,
            style: KolabingTextStyles.titleSmall.copyWith(
              color: context.colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Partner info
          Row(
            children: [
              // Partner avatar
              _PartnerAvatar(
                avatarUrl: collaboration.partnerAvatarUrl,
                initial: collaboration.partnerInitial,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  'with ${collaboration.partnerName}',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Date and status
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 12,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM yyyy').format(collaboration.completedAt),
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: context.colors.textTertiary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.checkCircle,
                      size: 10,
                      color: context.colors.success,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Completed',
                      style: KolabingTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.colors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Partner Avatar
// =============================================================================

class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.initial, this.avatarUrl});

  final String? avatarUrl;
  final String initial;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) =>
              _InitialCircle(initial: initial, size: size),
        ),
      );
    }

    return _InitialCircle(initial: initial, size: size);
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        initial,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.onSurface,
        ),
      ),
    ),
  );
}
