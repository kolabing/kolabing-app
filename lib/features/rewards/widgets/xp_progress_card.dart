import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/xp_level.dart';
import '../providers/wallet_provider.dart';

/// Compact XP progress card for the community dashboard.
///
/// Shows current level, total XP, animated progress bar, and XP to next level.
/// Tapping navigates to the full XP hub (handled by [onTap]).
class XpProgressCard extends ConsumerWidget {
  const XpProgressCard({super.key, this.onTap, this.showNavigationCta = true});

  final VoidCallback? onTap;
  final bool showNavigationCta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletSummaryProvider);
    if (wallet == null) return const SizedBox.shrink();

    final level = wallet.level;
    final progress = wallet.levelProgress;
    final xpToNext = wallet.xpToNextLevel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.secondaryContainer,
          borderRadius: KolabingRadius.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level chip + XP total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LevelChip(level: level),
                Text(
                  '${wallet.totalXp} XP',
                  style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: context.colors.onSurface),
                ),
              ],
            ),

            const SizedBox(height: KolabingSpacing.sm),

            // Progress bar
            ClipRRect(
              borderRadius: KolabingRadius.borderRadiusRound,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor:
                      context.colors.secondary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colors.secondary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: KolabingSpacing.xs),

            // Sub-label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  level.isMaxLevel
                      ? 'Max level reached!'
                      : '$xpToNext XP to ${level.next?.title ?? ''}',
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
                ),
                if (onTap != null && showNavigationCta)
                  Row(
                    children: [
                      Text(
                        'View progress',
                        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: context.colors.onSurface,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level chip
// ---------------------------------------------------------------------------

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final XpLevel level;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: context.colors.secondary.withValues(alpha: 0.15),
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.shield,
              size: 12,
              color: context.colors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              'LVL ${level.number} · ${level.title}',
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.secondary, letterSpacing: 0.3),
            ),
          ],
        ),
      );
}
