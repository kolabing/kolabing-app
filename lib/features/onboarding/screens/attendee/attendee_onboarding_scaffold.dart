import 'package:flutter/material.dart';

import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Shared chrome for the 4 attendee onboarding steps: a step counter, back +
/// optional skip in the header, a title/subtitle, the step body, and a bottom
/// primary button. Keeps each step screen focused on its own field.
class AttendeeOnboardingScaffold extends StatelessWidget {
  const AttendeeOnboardingScaffold({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.onSkip,
    this.canProceed = true,
    this.busy = false,
    super.key,
  });

  static const int totalSteps = 4;

  final int step;
  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool canProceed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back · step counter · skip
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.sm,
              ),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: busy ? null : onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 20,
                        color: KolabingColors.onSurface,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.attendeeOnboardingStepCounter(step, totalSteps),
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  if (onSkip != null)
                    TextButton(
                      onPressed: busy ? null : onSkip,
                      child: Text(l10n.commonSkip),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: step / totalSteps,
                  minHeight: 4,
                  backgroundColor: KolabingColors.surfaceVariant,
                  color: KolabingColors.primary,
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: KolabingSpacing.xl),
                    Text(
                      title,
                      style: KolabingTextStyles.bodyLarge.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: KolabingColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      subtitle,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xl),
                    child,
                    const SizedBox(height: KolabingSpacing.xl),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (canProceed && !busy) ? onPrimary : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor: KolabingColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KolabingColors.onPrimary,
                          ),
                        )
                      : Text(
                          primaryLabel,
                          style: KolabingTextStyles.button.copyWith(
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
