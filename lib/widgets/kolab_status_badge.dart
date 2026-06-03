import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

/// Shared pastel pill badge for status labels across all My Kolabs sections.
class KolabStatusBadge extends StatelessWidget {
  const KolabStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Text(
        label,
        style: KolabingTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static (Color, Color, String) _resolve(String status) =>
      switch (status.toLowerCase()) {
        'published' => (
          KolabingColors.activeBg,
          KolabingColors.activeText,
          'PUBLISHED',
        ),
        'draft' => (
          KolabingColors.completedBg,
          KolabingColors.completedText,
          'DRAFT',
        ),
        'closed' => (
          KolabingColors.completedBg,
          KolabingColors.completedText,
          'CLOSED',
        ),
        'completed' => (
          KolabingColors.completedBg,
          KolabingColors.completedText,
          'COMPLETED',
        ),
        'scheduled' => (
          KolabingColors.secondaryContainer,
          KolabingColors.secondary,
          'SCHEDULED',
        ),
        'in_progress' || 'active' => (
          KolabingColors.activeBg,
          KolabingColors.activeText,
          'IN PROGRESS',
        ),
        'pending_confirmation' => (
          KolabingColors.pendingBg,
          KolabingColors.pendingText,
          'WAITING CONFIRM',
        ),
        'pending' => (
          KolabingColors.pendingBg,
          KolabingColors.pendingText,
          'PENDING',
        ),
        'accepted' => (
          KolabingColors.activeBg,
          KolabingColors.activeText,
          'ACCEPTED',
        ),
        'declined' => (
          KolabingColors.errorBg,
          KolabingColors.errorText,
          'DECLINED',
        ),
        'withdrawn' => (
          KolabingColors.surfaceVariant,
          KolabingColors.textTertiary,
          'WITHDRAWN',
        ),
        'cancelled' => (
          KolabingColors.errorBg,
          KolabingColors.errorText,
          'CANCELLED',
        ),
        _ => (
          KolabingColors.surfaceVariant,
          KolabingColors.textTertiary,
          status.toUpperCase(),
        ),
      };
}
