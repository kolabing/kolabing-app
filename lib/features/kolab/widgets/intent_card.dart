import 'package:flutter/material.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

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
        color: isSelected ? context.colors.softYellow : Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.hairline,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? null : [KolabingShadows.card],
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
                  ? context.colors.primary.withValues(alpha: 0.2)
                  : context.colors.background,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? context.colors.onPrimary
                    : context.colors.onSurfaceVariant,
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
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xxxs),
                Text(
                  subtitle,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
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
                color: context.colors.softYellow,
                borderRadius: KolabingRadius.borderRadiusSm,
              ),
              child: Text(
                badge!,
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
