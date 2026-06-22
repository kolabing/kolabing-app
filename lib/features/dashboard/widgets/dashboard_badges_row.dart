import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../rewards/models/reward_badge.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Horizontally scrollable badge chips row for the community dashboard.
///
/// Reads [RewardBadge] list from [walletProvider].
/// Earned badges use a warm yellow tint; locked ones are greyed out.
class DashboardBadgesRow extends ConsumerWidget {
  const DashboardBadgesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(walletProvider.select((s) => s.badges));
    if (badges.isEmpty) return const SizedBox.shrink();

    final c = context.colors;
    final earnedCount = badges.where((b) => b.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BADGES',
              style: KolabingTextStyles.labelLarge.copyWith(
                color: c.onSurface,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '$earnedCount earned',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: c.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (context, index) => const SizedBox(width: KolabingSpacing.xs),
            itemBuilder: (context, i) => _BadgeChip(badge: badges[i]),
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final RewardBadge badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final earned = badge.isUnlocked;

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
      decoration: BoxDecoration(
        color: earned ? c.softYellow : c.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(
          color: earned ? c.primaryDark.withValues(alpha: 0.6) : c.hairline,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.slug.icon,
            size: 20,
            color: earned ? c.onSurface : c.muted,
          ),
          const SizedBox(height: 4),
          Text(
            badge.slug.shortName.replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 8,
              color: earned ? c.onSurfaceVariant : c.muted,
              fontWeight: earned ? FontWeight.w600 : FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
