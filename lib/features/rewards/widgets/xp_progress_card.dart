import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
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

    const xpBg = Color(0xFFECEAF6);
    const xpInk = Color(0xFF5E5784);
    const xpFill = Color(0xFFB9AEE8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: xpBg,
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
                  style: KolabingTextStyles.displaySmall.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: xpInk,
                  ),
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
                  backgroundColor: const Color(0xFF5E5784).withValues(alpha: 0.14),
                  valueColor: const AlwaysStoppedAnimation<Color>(xpFill),
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
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: xpInk),
                ),
                if (onTap != null && showNavigationCta)
                  Row(
                    children: [
                      Text(
                        'View progress ›',
                        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: xpInk),
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
          color: Colors.white,
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.shield,
              size: 12,
              color: Color(0xFF5E5784),
            ),
            const SizedBox(width: 4),
            Text(
              'LVL ${level.number} · ${level.title}',
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF5E5784), letterSpacing: 0.3),
            ),
          ],
        ),
      );
}
