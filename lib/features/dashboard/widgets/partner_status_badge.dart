import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/dashboard_model.dart';

/// Subtle, professional badge showing a business's partner status
/// (New/Active/Trusted Partner, Community Favourite).
///
/// Deliberately quiet — a small pill, not an achievement banner. Renders
/// nothing for New/Active Partner (no icon), since status is only worth
/// calling out once it's actually been earned.
class PartnerStatusBadge extends StatelessWidget {
  const PartnerStatusBadge({super.key, required this.partnerStatus});

  final PartnerStatus? partnerStatus;

  @override
  Widget build(BuildContext context) {
    final status = partnerStatus;
    if (status == null || status.icon.isEmpty) return const SizedBox.shrink();

    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: c.softYellow,
        borderRadius: KolabingRadius.borderRadiusPill,
        border: Border.all(color: c.primaryDark.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
