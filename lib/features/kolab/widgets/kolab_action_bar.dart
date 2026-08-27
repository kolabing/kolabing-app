import 'package:flutter/material.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';

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
      border: Border(top: BorderSide(color: context.colors.darkBorder)),
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
// Primary filled button — delegates to shared KolabingButton
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
  Widget build(BuildContext context) => KolabingButton(
    label: label,
    onPressed: onPressed,
    variant: KolabingButtonVariant.primary,
    size: KolabingButtonSize.compact,
    isLoading: isLoading,
    isDisabled: onPressed == null && !isLoading,
  );
}

// ---------------------------------------------------------------------------
// Outlined / secondary button — delegates to shared KolabingButton
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
  Widget build(BuildContext context) => KolabingButton(
    label: label,
    onPressed: isLoading ? null : onPressed,
    variant: KolabingButtonVariant.secondary,
    size: KolabingButtonSize.compact,
    isLoading: isLoading,
    isDisabled: !isLoading && onPressed == null,
  );
}
