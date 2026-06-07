import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Sage-green XP summary card for the redesigned Community Dashboard.
///
/// Non-tappable. Shows level chip, total XP, "To next level" counter,
/// and an animated progress bar. Does NOT navigate anywhere.
class CommunityXpSummaryCard extends ConsumerWidget {
  const CommunityXpSummaryCard({super.key});

  static const _cardBg = Color(0xFFE8EFE0);
  static const _inkDark = Color(0xFF2E4020);
  static const _inkMid = Color(0xFF3D5229);
  static const _progressFill = Color(0xFF5A7A3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletSummaryProvider);
    if (wallet == null) return const SizedBox.shrink();

    final level = wallet.level;
    final progress = wallet.levelProgress;
    final xpToNext = wallet.xpToNextLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: const Color(0xFF3D5229).withValues(alpha: 0.15)),
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
                        color: _inkMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$xpToNext',
                      style: KolabingTextStyles.displaySmall.copyWith(
                        fontSize: 24,
                        color: _inkDark,
                      ),
                    ),
                    Text(
                      'XP needed',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: _inkMid,
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
              color: _inkDark,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'XP POINTS',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _inkMid,
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
                backgroundColor: const Color(0xFF3D5229).withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(_progressFill),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2E4020),
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.shield, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'LEVEL $levelNumber',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
}
