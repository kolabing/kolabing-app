import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';

/// A small yellow nudge card displayed on a completed collaboration to remind
/// the user they earned a point and can earn another by posting a review.
///
/// Typically placed at the bottom of a collaboration detail screen when the
/// collaboration status is `completed`.
class CollaborationRewardNudge extends StatelessWidget {
  const CollaborationRewardNudge({super.key});

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.softYellow,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: KolabingColors.softYellowBorder),
      ),
      child: Row(
        children: [
          // Star icon
          const Icon(
            LucideIcons.star,
            size: 20,
            color: KolabingColors.textPrimary,
          ),
          const SizedBox(width: KolabingSpacing.xs),

          // Text content
          Expanded(
            child: Row(
              children: [
                Text(
                  '+1 point earned',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                const SizedBox(width: KolabingSpacing.xxs),
                Flexible(
                  child: Text(
                    'Post a review to earn another',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CTA text button
          TextButton(
            onPressed: () {
              // Navigation to post review is handled by the parent screen.
              // This is a presentational widget; the parent should wrap or
              // replace this callback as needed.
            },
            style: TextButton.styleFrom(
              foregroundColor: KolabingColors.textPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Post review \u2192',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
}
