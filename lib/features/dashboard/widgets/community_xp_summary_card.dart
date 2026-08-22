import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/typography.dart';
import '../../rewards/providers/wallet_provider.dart';

// Design tokens for the yellow XP card
const _cardBg = Color(0xFFFFE28C); // primary brand yellow
const _inkDark = Color(0xFF19150F);
const _mutedLabel = Color(0xFF9A7C28); // amber-on-yellow muted label
const _orangeFill = Color(0xFFFF6114); // progress bar fill

/// Yellow XP summary card for the Community Dashboard.
///
/// Matches the referral card visual language: solid yellow, black pill badge,
/// bold numerics, orange progress fill. Styling only — all data wiring is unchanged.
class CommunityXpSummaryCard extends ConsumerWidget {
  const CommunityXpSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletSummaryProvider);
    if (wallet == null) return const SizedBox.shrink();

    final level = wallet.level;
    final progress = wallet.levelProgress;
    final xpToNext = wallet.xpToNextLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: level badge (left) + to-next-level stack (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelBadge(levelNumber: level.number),
              const Spacer(),
              if (!level.isMaxLevel)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'To next level',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _mutedLabel,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$xpToNext',
                      style: KolabingTextStyles.statNumber.copyWith(
                        fontSize: 34,
                        color: _inkDark,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      'XP NEEDED',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _mutedLabel,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: KolabingSpacing.sm),

          // Big XP number
          Text(
            '${wallet.totalXp}',
            style: KolabingTextStyles.statNumber.copyWith(
              fontSize: 56,
              color: _inkDark,
              height: 0.92,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'XP POINTS',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _mutedLabel,
              letterSpacing: 1.4,
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
                minHeight: 8,
                backgroundColor: const Color(
                  0xFF19150F,
                ).withValues(alpha: 0.14),
                valueColor: const AlwaysStoppedAnimation<Color>(_orangeFill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.levelNumber});

  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF19150F),
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.shield,
            size: 11,
            color: _cardBg, // yellow icon on black pill
          ),
          const SizedBox(width: 5),
          Text(
            'LEVEL $levelNumber',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _cardBg,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
