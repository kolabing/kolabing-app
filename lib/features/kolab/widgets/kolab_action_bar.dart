import 'package:flutter/material.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';

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
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.colors.darkBorder),
          ),
        ),
        child: isLastStep
            ? _buildLastStepRow(context)
            : _buildNavigationRow(context),
      );

  Widget _buildNavigationRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        if (!isFirstStep) ...[
          Expanded(
            child: _OutlinedActionButton(
              label: l10n.commonBack,
              onPressed: onBack,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
        ],
        Expanded(
          child: _PrimaryActionButton(
            label: l10n.commonNext,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }

  Widget _buildLastStepRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _OutlinedActionButton(
            label: l10n.kolabActionBarSaveDraft,
            onPressed: isSubmitting || isPublishing ? null : onSaveDraft,
            isLoading: isSubmitting,
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: _PrimaryActionButton(
            label: l10n.kolabActionBarPublish,
            onPressed: isSubmitting || isPublishing ? null : onPublish,
            isLoading: isPublishing,
          ),
        ),
      ],
    );
  }
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
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            disabledBackgroundColor:
                context.colors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.onPrimary,
                  ),
                )
              : Text(
                  label,
                  style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.0),
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
            foregroundColor: context.colors.onSurface,
            side: BorderSide(color: context.colors.darkBorder),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.onSurface,
                  ),
                )
              : Text(
                  label,
                  style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.0),
                ),
        ),
      );
}
