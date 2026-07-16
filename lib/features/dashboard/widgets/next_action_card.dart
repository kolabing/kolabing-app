import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/dashboard_model.dart';

/// Single next-best-action card. `title`/`body` are server-provided display
/// copy (backend-passed text, no i18n lookup on this side — same exception
/// as other dynamic backend text per CLAUDE.md's i18n rule).
///
/// Renders nothing when [nextAction] is null — there is no persistent
/// "nothing to do" state, matching the backend's rule chain which returns
/// null once a business is caught up.
class NextActionCard extends StatelessWidget {
  const NextActionCard({super.key, required this.nextAction, this.onTap});

  final NextAction? nextAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final action = nextAction;
    if (action == null) return const SizedBox.shrink();

    final c = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KolabingRadius.borderRadiusLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(KolabingSpacing.xs),
                decoration: BoxDecoration(
                  color: c.softYellow,
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
                child: Icon(LucideIcons.sparkles, size: 18, color: c.onSurface),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                    if (action.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.body,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: KolabingSpacing.xs),
                Icon(LucideIcons.chevronRight, size: 18, color: c.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
