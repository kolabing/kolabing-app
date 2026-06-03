// lib/features/dashboard/widgets/earn_xp_action_card.dart
import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';

/// A single XP earning action row for the mission board.
///
/// Shows a pastel icon, title, short description, and either a purple
/// "+N XP" badge (pending) or a green "✓ Done" badge (completed).
class EarnXpActionCard extends StatelessWidget {
  const EarnXpActionCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.xpReward,
    super.key,
    this.isDone = false,
  });

  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String description;
  final int xpReward;
  final bool isDone;

  static const _headingColor = Color(0xFF36322A);
  static const _captionColor = Color(0xFF928B7C);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: const Color(0xFFE8E2D6)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: _headingColor),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _headingColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: _captionColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.xs),
          // Badge
          _Badge(xpReward: xpReward, isDone: isDone),
        ],
      ),
    );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.xpReward, required this.isDone});

  final int xpReward;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final bg = isDone
        ? const Color(0xFFE8F5EE)
        : const Color(0xFFEDE8FB);
    final textColor = isDone
        ? const Color(0xFF2E7D52)
        : const Color(0xFF7B5EA7);
    final label = isDone ? '✓ Done' : '+$xpReward XP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? const Color(0xFF2E7D52).withValues(alpha: 0.2)
              : const Color(0xFF7B5EA7).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
