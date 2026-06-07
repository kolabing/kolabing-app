// lib/features/dashboard/widgets/community_stats_strip.dart
import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// A compact 4-pill horizontal stats strip for the XP-first dashboard layouts.
///
/// Replaces the 2×2 [DashboardStatCard] grid with a denser single row.
class CommunityStatsStrip extends StatelessWidget {
  const CommunityStatsStrip({
    required this.pending,
    required this.accepted,
    required this.active,
    required this.completed,
    super.key,
  });

  final int pending;
  final int accepted;
  final int active;
  final int completed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StatPill(count: pending, label: 'PENDING'),
      const SizedBox(width: KolabingSpacing.xs),
      _StatPill(count: active, label: 'ACTIVE'),
      const SizedBox(width: KolabingSpacing.xs),
      _StatPill(count: completed, label: 'DONE'),
      const SizedBox(width: KolabingSpacing.xs),
      _StatPill(count: accepted, label: 'ACCEPTED'),
    ],
  );
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: KolabingTextStyles.displaySmall.copyWith(
                fontSize: 20,
                color: c.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 9,
                color: c.textTertiary,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
