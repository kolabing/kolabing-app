import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Sage-green XP summary card for the redesigned Community Dashboard.
///
/// Non-tappable. Shows level chip, total XP, "To next level" counter,
/// and an animated progress bar. Does NOT navigate anywhere.
class CommunityXpSummaryCard extends ConsumerWidget {
  const CommunityXpSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final wallet = ref.watch(walletSummaryProvider);
    if (wallet == null) return const SizedBox.shrink();

    final cardBg = c.categorySageBg;
    final inkDark = c.categorySageText;
    final inkMid = c.categorySageText;
    final progressFill = c.success;

    final level = wallet.level;
    final progress = wallet.levelProgress;
    final xpToNext = wallet.xpToNextLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: inkMid.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level chip
              _LevelChip(levelNumber: level.number, levelTitle: level.title),
              const Spacer(),
              // To next level
              if (!level.isMaxLevel) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'To next level',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: inkMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$xpToNext',
                      style: KolabingTextStyles.displaySmall.copyWith(
                        fontSize: 24,
                        color: inkDark,
                      ),
                    ),
                    Text(
                      'XP needed',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: inkMid,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          // Big XP number
          Text(
            '${wallet.totalXp}',
            style: KolabingTextStyles.displaySmall.copyWith(
              fontSize: 40,
              color: inkDark,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'XP POINTS',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: inkMid,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          // Animated progress bar
          ClipRRect(
            borderRadius: KolabingRadius.borderRadiusRound,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: inkMid.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(progressFill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.levelNumber, required this.levelTitle});

  final int levelNumber;
  final String levelTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: c.categorySageText,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shield, size: 11, color: c.textOnDark),
          const SizedBox(width: 4),
          Text(
            'LEVEL $levelNumber',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.textOnDark,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
