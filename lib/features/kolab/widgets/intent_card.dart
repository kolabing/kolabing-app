import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';

/// A selectable card for choosing a Kolab intent type.
///
/// When [isSelected] is true the card shows a soft yellow background with a
/// primary border. An optional [badge] can be displayed as a small chip on the
/// trailing side.
class IntentCard extends StatelessWidget {
  const IntentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
    this.badge,
    this.isSelected = false,
  });

  /// Leading icon displayed inside a circular container.
  final IconData icon;

  /// Primary label text.
  final String title;

  /// Secondary description text.
  final String subtitle;

  /// Optional badge text shown as a small chip on the right side.
  final String? badge;

  /// Whether this card is currently selected.
  final bool isSelected;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(KolabingSpacing.lg - 4), // 20dp
          decoration: BoxDecoration(
            color: isSelected
                ? KolabingColors.softYellow
                : KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(
              color:
                  isSelected ? KolabingColors.primary : KolabingColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon in circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? KolabingColors.primary.withValues(alpha: 0.2)
                      : KolabingColors.background,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? KolabingColors.onPrimary
                        : KolabingColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xxxs),
                    Text(
                      subtitle,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: KolabingColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Badge
              if (badge != null) ...[
                const SizedBox(width: KolabingSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.xs,
                    vertical: KolabingSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: KolabingColors.softYellow,
                    borderRadius: KolabingRadius.borderRadiusSm,
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
