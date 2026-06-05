import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/challenge_completion.dart';
import 'difficulty_badge.dart';
import 'points_badge.dart';

/// Card widget displaying a challenge completion record
class ChallengeCompletionCard extends StatelessWidget {
  const ChallengeCompletionCard({
    super.key,
    required this.completion,
    this.onVerify,
    this.onReject,
    this.onTap,
  });

  final ChallengeCompletion completion;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? context.colors.darkSurface : context.colors.surface;
    final textColor =
        isDark ? context.colors.textOnDark : context.colors.onSurface;
    final secondaryTextColor =
        isDark ? context.colors.textTertiary : context.colors.onSurfaceVariant;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? context.colors.darkBorder : context.colors.darkBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status icon
                  _buildStatusIcon(),
                  const SizedBox(width: KolabingSpacing.sm),

                  // Challenge name and event
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          completion.challengeName ?? l10n.challengeCompletionDefaultName,
                          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (completion.eventName != null)
                          Text(
                            completion.eventName!,
                            style: KolabingTextStyles.captionSecondary.copyWith(color: secondaryTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Points badge
                  PointsBadge(
                    points: completion.pointsEarned,
                    isEarned: completion.isVerified,
                  ),
                ],
              ),

              const SizedBox(height: KolabingSpacing.sm),

              // Info row
              Row(
                children: [
                  // Difficulty badge
                  if (completion.challengeDifficulty != null)
                    DifficultyBadge(
                      difficulty: completion.challengeDifficulty!,
                    ),

                  const Spacer(),

                  // Status badge
                  _buildStatusBadge(l10n),
                ],
              ),

              // Verification actions (if pending and user is verifier)
              if (completion.isPending && (onVerify != null || onReject != null))
                Padding(
                  padding: const EdgeInsets.only(top: KolabingSpacing.sm),
                  child: Row(
                    children: [
                      // Challenger info
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.user,
                              size: 14,
                              color: context.colors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                completion.challengerName ?? l10n.challengeCompletionDefaultChallenger,
                                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: secondaryTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      if (onReject != null)
                        _ActionButton(
                          icon: LucideIcons.x,
                          label: l10n.challengeCompletionReject,
                          color: context.colors.error,
                          onPressed: onReject!,
                        ),
                      if (onVerify != null) ...[
                        const SizedBox(width: KolabingSpacing.xs),
                        _ActionButton(
                          icon: LucideIcons.check,
                          label: l10n.challengeCompletionVerify,
                          color: context.colors.success,
                          onPressed: onVerify!,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    Color bgColor;

    switch (completion.status) {
      case ChallengeCompletionStatus.verified:
        icon = LucideIcons.checkCircle;
        color = context.colors.success;
        bgColor = context.colors.success.withValues(alpha: 0.15);
      case ChallengeCompletionStatus.rejected:
        icon = LucideIcons.xCircle;
        color = context.colors.error;
        bgColor = context.colors.error.withValues(alpha: 0.15);
      case ChallengeCompletionStatus.pending:
        icon = LucideIcons.clock;
        color = context.colors.warning;
        bgColor = context.colors.warning.withValues(alpha: 0.15);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  Widget _buildStatusBadge(AppLocalizations l10n) {
    String text;
    Color bgColor;
    Color textColor;

    switch (completion.status) {
      case ChallengeCompletionStatus.verified:
        text = l10n.challengeCompletionStatusVerified;
        bgColor = context.colors.activeBg;
        textColor = context.colors.activeText;
      case ChallengeCompletionStatus.rejected:
        text = l10n.challengeCompletionStatusRejected;
        bgColor = context.colors.errorBg;
        textColor = context.colors.errorText;
      case ChallengeCompletionStatus.pending:
        text = l10n.challengeCompletionStatusPending;
        bgColor = context.colors.pendingBg;
        textColor = context.colors.pendingText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
