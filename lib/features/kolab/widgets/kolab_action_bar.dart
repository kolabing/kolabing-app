import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';

/// Bottom action bar for the Kolab creation flow.
///
/// On intermediate steps it shows Back + Next buttons.
/// On the final step it shows Save Draft + Publish buttons.
/// Buttons display a loading indicator when their respective actions are
/// in progress.
class KolabActionBar extends StatelessWidget {
  const KolabActionBar({
    super.key,
    this.onBack,
    this.onNext,
    this.onSaveDraft,
    this.onPublish,
    this.isLastStep = false,
    this.isFirstStep = false,
    this.isSubmitting = false,
    this.isPublishing = false,
  });

  /// Called when the user taps the Back button.
  final VoidCallback? onBack;

  /// Called when the user taps the Next button.
  final VoidCallback? onNext;

  /// Called when the user taps the Save Draft button on the last step.
  final VoidCallback? onSaveDraft;

  /// Called when the user taps the Publish button on the last step.
  final VoidCallback? onPublish;

  /// Whether this is the final step (shows Save Draft + Publish).
  final bool isLastStep;

  /// Whether this is the first step (hides Back button).
  final bool isFirstStep;

  /// Whether the save draft action is in progress.
  final bool isSubmitting;

  /// Whether the publish action is in progress.
  final bool isPublishing;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: KolabingSpacing.md,
          right: KolabingSpacing.md,
          top: KolabingSpacing.sm,
          bottom: MediaQuery.of(context).padding.bottom + KolabingSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: KolabingColors.surface,
          border: Border(
            top: BorderSide(color: KolabingColors.border),
          ),
        ),
        child: isLastStep ? _buildLastStepRow() : _buildNavigationRow(),
      );

  Widget _buildNavigationRow() => Row(
        children: [
          if (!isFirstStep) ...[
            Expanded(
              child: _OutlinedActionButton(
                label: 'BACK',
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
          ],
          Expanded(
            child: _PrimaryActionButton(
              label: 'NEXT',
              onPressed: onNext,
            ),
          ),
        ],
      );

  Widget _buildLastStepRow() => Row(
        children: [
          Expanded(
            child: _OutlinedActionButton(
              label: 'SAVE DRAFT',
              onPressed: isSubmitting || isPublishing ? null : onSaveDraft,
              isLoading: isSubmitting,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: _PrimaryActionButton(
              label: 'PUBLISH',
              onPressed: isSubmitting || isPublishing ? null : onPublish,
              isLoading: isPublishing,
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Primary filled button (yellow background)
// ---------------------------------------------------------------------------

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: KolabingLayout.buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            disabledBackgroundColor:
                KolabingColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KolabingColors.onPrimary,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.darkerGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Outlined button (white background, border)
// ---------------------------------------------------------------------------

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: KolabingLayout.buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: KolabingColors.textPrimary,
            side: const BorderSide(color: KolabingColors.border),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KolabingColors.textPrimary,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.darkerGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      );
}
