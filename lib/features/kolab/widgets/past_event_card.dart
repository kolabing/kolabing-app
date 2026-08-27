import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/kolab.dart';

/// Card for displaying or adding a past event in the Kolab creation flow.
///
/// When [event] is `null`, an "add" card with a dashed border and plus icon is
/// rendered. When an event is provided, it shows the event details with a
/// remove button.
class PastEventCard extends StatelessWidget {
  const PastEventCard({
    required this.onAdd,
    super.key,
    this.event,
    this.onRemove,
  });

  /// The past event data. When `null` the card renders in "add" mode.
  final PastEvent? event;

  /// Called when the add card is tapped.
  final VoidCallback onAdd;

  /// Called when the remove button is tapped on an existing event card.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) =>
      event == null ? _buildAddCard(context) : _buildEventCard(context);

  // ---------------------------------------------------------------------------
  // Add mode — dashed border placeholder
  // ---------------------------------------------------------------------------

  Widget _buildAddCard(BuildContext context) => GestureDetector(
    onTap: onAdd,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: context.colors.hairline),
        boxShadow: [KolabingShadows.card],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.plus,
              size: 20,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            'Add a past event',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Existing event card
  // ---------------------------------------------------------------------------

  Widget _buildEventCard(BuildContext context) {
    final e = event!;
    final formattedDate = DateFormat('MMM dd, yyyy').format(e.date);

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: context.colors.hairline),
        boxShadow: [KolabingShadows.card],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.calendar,
              size: 18,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: KolabingSpacing.xxxs),
                Text(
                  formattedDate,
                  style: KolabingTextStyles.captionSecondary.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (e.partnerName != null && e.partnerName!.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.xxxs),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 13,
                        color: context.colors.textTertiary,
                      ),
                      const SizedBox(width: KolabingSpacing.xxs),
                      Expanded(
                        child: Text(
                          e.partnerName!,
                          style: KolabingTextStyles.captionSecondary.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (e.photos.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.xxs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: KolabingSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: KolabingRadius.borderRadiusXs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 12,
                          color: context.colors.textTertiary,
                        ),
                        const SizedBox(width: KolabingSpacing.xxs),
                        Text(
                          '${e.photos.length} photo${e.photos.length == 1 ? '' : 's'}',
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (e.videos.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.xxs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: KolabingSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: KolabingRadius.borderRadiusXs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.video,
                          size: 12,
                          color: context.colors.textTertiary,
                        ),
                        const SizedBox(width: KolabingSpacing.xxs),
                        Text(
                          '${e.videos.length} video${e.videos.length == 1 ? '' : 's'}',
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Remove button
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: context.colors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
