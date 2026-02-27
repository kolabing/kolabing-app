import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? KolabingColors.darkSurface : KolabingColors.surface;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;
    final secondaryTextColor =
        isDark ? KolabingColors.textTertiary : KolabingColors.textSecondary;

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
              color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
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
                          completion.challengeName ?? 'Challenge',
                          style: GoogleFonts.rubik(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (completion.eventName != null)
                          Text(
                            completion.eventName!,
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
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
                  _buildStatusBadge(),
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
                            const Icon(
                              LucideIcons.user,
                              size: 14,
                              color: KolabingColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                completion.challengerName ?? 'Challenger',
                                style: GoogleFonts.openSans(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
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
                          label: 'Reject',
                          color: KolabingColors.error,
                          onPressed: onReject!,
                        ),
                      if (onVerify != null) ...[
                        const SizedBox(width: KolabingSpacing.xs),
                        _ActionButton(
                          icon: LucideIcons.check,
                          label: 'Verify',
                          color: KolabingColors.success,
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
        color = KolabingColors.success;
        bgColor = KolabingColors.success.withValues(alpha: 0.15);
      case ChallengeCompletionStatus.rejected:
        icon = LucideIcons.xCircle;
        color = KolabingColors.error;
        bgColor = KolabingColors.error.withValues(alpha: 0.15);
      case ChallengeCompletionStatus.pending:
        icon = LucideIcons.clock;
        color = KolabingColors.warning;
        bgColor = KolabingColors.warning.withValues(alpha: 0.15);
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

  Widget _buildStatusBadge() {
    String text;
    Color bgColor;
    Color textColor;

    switch (completion.status) {
      case ChallengeCompletionStatus.verified:
        text = 'Verified';
        bgColor = KolabingColors.activeBg;
        textColor = KolabingColors.activeText;
      case ChallengeCompletionStatus.rejected:
        text = 'Rejected';
        bgColor = KolabingColors.errorBg;
        textColor = KolabingColors.errorText;
      case ChallengeCompletionStatus.pending:
        text = 'Pending';
        bgColor = KolabingColors.pendingBg;
        textColor = KolabingColors.pendingText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
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
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
