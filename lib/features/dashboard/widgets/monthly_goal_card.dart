import 'package:flutter/material.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/dashboard_model.dart';

/// Rolling calendar-month collaboration goal, shown as progress toward a
/// target. Deliberately not a streak — there is no "missed"/"broken" visual
/// state, it just shows completed/goal for the current month.
class MonthlyGoalCard extends StatelessWidget {
  const MonthlyGoalCard({super.key, required this.monthlyGoal});

  final MonthlyGoal? monthlyGoal;

  @override
  Widget build(BuildContext context) {
    final goal = monthlyGoal;
    if (goal == null || goal.goal <= 0) return const SizedBox.shrink();

    final c = context.colors;
    final progress = (goal.completed / goal.goal).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboardMonthlyGoalTitle,
                style: KolabingTextStyles.labelLarge.copyWith(
                  color: c.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                l10n.dashboardMonthlyGoalProgress(goal.completed, goal.goal),
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: goal.met ? c.primaryDark : c.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xs),
          ClipRRect(
            borderRadius: KolabingRadius.borderRadiusPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: c.hairline,
              valueColor: AlwaysStoppedAnimation(c.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}
