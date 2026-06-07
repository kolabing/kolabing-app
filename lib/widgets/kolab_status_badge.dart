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
    final (bg, fg, label) = _resolve(status, context.colors);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xxxs,
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
        ),
      ),
    );
  }

  static (Color, Color, String) _resolve(
    String status,
    KolabingColorTokens c,
  ) =>
      switch (status.toLowerCase()) {
        'published' => (c.activeBg, c.activeText, 'PUBLISHED'),
        'draft' => (c.completedBg, c.completedText, 'DRAFT'),
        'closed' => (c.completedBg, c.completedText, 'CLOSED'),
        'completed' => (c.completedBg, c.completedText, 'COMPLETED'),
        'scheduled' => (c.secondaryContainer, c.secondary, 'SCHEDULED'),
        'in_progress' || 'active' => (c.activeBg, c.activeText, 'IN PROGRESS'),
        'pending_confirmation' => (
          c.pendingBg,
          c.pendingText,
          'WAITING CONFIRM',
        ),
        'pending' => (c.pendingBg, c.pendingText, 'PENDING'),
        'accepted' => (c.activeBg, c.activeText, 'ACCEPTED'),
        'declined' => (c.errorBg, c.errorText, 'DECLINED'),
        'withdrawn' => (c.surfaceVariant, c.textTertiary, 'WITHDRAWN'),
        'cancelled' => (c.errorBg, c.errorText, 'CANCELLED'),
        _ => (c.surfaceVariant, c.textTertiary, status.toUpperCase()),
      };
}
