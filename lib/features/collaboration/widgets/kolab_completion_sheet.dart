import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../../config/constants/radius.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/collaboration.dart';
import '../services/collaboration_completion_service.dart';

/// Result returned after the completion sheet closes.
class KolabCompletionResult {
  const KolabCompletionResult({
    required this.collaboration,
    required this.totalXpEarned,
  });

  final Collaboration collaboration;
  final int totalXpEarned;
}

/// The gamified, multi-step Kolab completion bottom sheet.
///
/// Flow (feedback is forced — the sheet is non-dismissible and you cannot reach
/// the celebration / close without submitting feedback):
///   Step 0 — "Did the Kolab happen?" confirmation → marks complete
///   Step 1 — **Required feedback** (star rating required + optional comment +
///            would-Kolab-again) → submits before celebrating
///   Step 2 — Celebration + XP preview
///   Step 3 — Done with confetti summary
///
/// NOTE: until the backend adds `POST /collaborations/{id}/feedback` and makes
/// `/complete` require it (BACKLOG IF-5 / docs/tickets/2026-06-01-feedback-flow),
/// completion is marked first and the feedback (the lean `/review` endpoint) is
/// forced immediately after as an un-skippable closing step. Once the backend
/// gate ships this becomes atomic server-side with richer fields.
///
/// Shows [KolabCompletionResult] on close, or null if user dismissed early.
class KolabCompletionSheet extends StatefulWidget {
  const KolabCompletionSheet({
    required this.collaborationId,
    required this.partnerName,
    super.key,
  });

  final String collaborationId;
  final String partnerName;

  static Future<KolabCompletionResult?> show(
    BuildContext context, {
    required String collaborationId,
    required String partnerName,
  }) {
    return showModalBottomSheet<KolabCompletionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => KolabCompletionSheet(
        collaborationId: collaborationId,
        partnerName: partnerName,
      ),
    );
  }

  @override
  State<KolabCompletionSheet> createState() => _KolabCompletionSheetState();
}

class _KolabCompletionSheetState extends State<KolabCompletionSheet>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _isLoading = false;
  String? _error;

  // Required-feedback step state (forced before celebration).
  int? _rating;
  bool? _wouldAgain;
  final _commentController = TextEditingController();
  bool _isSubmittingFeedback = false;
  String? _feedbackError;

  // Result tracking
  Collaboration? _updatedCollaboration;
  static const int _baseXp = 10;

  late final AnimationController _celebrationController;
  late final AnimationController _xpCountController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _xpCountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _celebrationController.dispose();
    _xpCountController.dispose();
    super.dispose();
  }

  /// Step 0 → marks the collaboration complete, then advances to the REQUIRED
  /// feedback step (no celebration yet — feedback must be given first).
  Future<void> _onConfirmComplete() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final collab = await completeCollaboration(widget.collaborationId);
      _updatedCollaboration = collab;
      setState(() {
        _step = 1; // required feedback
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = AppLocalizations.of(context).commonErrorGeneric;
      });
    }
  }

  /// Step 1 → submits the required feedback, then unlocks the celebration.
  /// Rating is mandatory; the sheet cannot be closed without it.
  Future<void> _onSubmitFeedback() async {
    final rating = _rating;
    if (rating == null) return;

    setState(() {
      _isSubmittingFeedback = true;
      _feedbackError = null;
    });

    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Session expired');
      }
      final comment = _commentController.text.trim();
      final payload = <String, dynamic>{
        'rating': rating,
        if (comment.isNotEmpty) 'body': comment,
        if (_wouldAgain != null) 'would_collaborate_again': _wouldAgain,
      };
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/collaborations/${widget.collaborationId}/review',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        unawaited(
          AnalyticsService.instance.capture(
            AnalyticsEvents.feedbackSubmitted,
            properties: {
              'collaboration_id': widget.collaborationId,
              'rating': rating,
            },
          ),
        );
        setState(() {
          _isSubmittingFeedback = false;
          _step = 2; // celebration
        });
        _celebrationController.forward();
        HapticFeedback.mediumImpact();
      } else {
        setState(() {
          _isSubmittingFeedback = false;
          _feedbackError =
              AppLocalizations.of(context).kolabCompletionSheetFeedbackError;
        });
      }
    } catch (_) {
      setState(() {
        _isSubmittingFeedback = false;
        _feedbackError =
            AppLocalizations.of(context).kolabCompletionSheetFeedbackError;
      });
    }
  }

  void _goToDone() => setState(() => _step = 3);

  void _close() {
    if (_updatedCollaboration != null) {
      Navigator.of(context).pop(KolabCompletionResult(
        collaboration: _updatedCollaboration!,
        totalXpEarned: _baseXp,
      ));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: context.colors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(KolabingRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepConfirm(
          key: const ValueKey(0),
          partnerName: widget.partnerName,
          isLoading: _isLoading,
          error: _error,
          onConfirm: _onConfirmComplete,
          onDismiss: _close,
        );
      case 1:
        return _StepFeedback(
          key: const ValueKey(1),
          partnerName: widget.partnerName,
          rating: _rating,
          wouldAgain: _wouldAgain,
          commentController: _commentController,
          isSubmitting: _isSubmittingFeedback,
          error: _feedbackError,
          onRatingChanged: (v) => setState(() => _rating = v),
          onWouldAgainChanged: (v) => setState(() => _wouldAgain = v),
          onSubmit: _rating == null ? null : _onSubmitFeedback,
          // Escape hatch: completion already succeeded server-side, so if
          // feedback keeps failing don't trap the user — let them finish later.
          // (They're re-prompted for feedback on next open per IF-5.)
          onFinishLater: _feedbackError != null ? _close : null,
        );
      case 2:
        return _StepCelebration(
          key: const ValueKey(2),
          scaleAnimation: _scaleAnimation,
          fadeAnimation: _fadeAnimation,
          baseXp: _baseXp,
          onContinue: _goToDone,
        );
      case 3:
        return _StepDone(
          key: const ValueKey(3),
          totalXp: _baseXp,
          onClose: _close,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Step 0 — Confirm
// =============================================================================

class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    super.key,
    required this.partnerName,
    required this.isLoading,
    required this.error,
    required this.onConfirm,
    required this.onDismiss,
  });

  final String partnerName;
  final bool isLoading;
  final String? error;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kolabCompletionConfirmTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            fontSize: 22,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kolabCompletionConfirmSubtitle(partnerName),
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.errorBg,
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            child: Text(
              error!,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: context.colors.error,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _PrimaryButton(
          label: isLoading
              ? l10n.kolabCompletionConfirmLoading
              : l10n.kolabCompletionConfirmCta,
          isLoading: isLoading,
          onTap: isLoading ? null : onConfirm,
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: l10n.kolabCompletionConfirmDismiss,
          onTap: onDismiss,
        ),
      ],
    );
  }
}

// =============================================================================
// Step 1 — Required feedback (the forced closing step)
// =============================================================================

class _StepFeedback extends StatelessWidget {
  const _StepFeedback({
    super.key,
    required this.partnerName,
    required this.rating,
    required this.wouldAgain,
    required this.commentController,
    required this.isSubmitting,
    required this.error,
    required this.onRatingChanged,
    required this.onWouldAgainChanged,
    required this.onSubmit,
    this.onFinishLater,
  });

  final String partnerName;
  final int? rating;
  final bool? wouldAgain;
  final TextEditingController commentController;
  final bool isSubmitting;
  final String? error;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<bool> onWouldAgainChanged;
  final VoidCallback? onSubmit;

  /// Shown only after a feedback submission error: completion already
  /// happened, so this lets the user exit instead of being trapped.
  final VoidCallback? onFinishLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kolabCompletionFeedbackTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            fontSize: 22,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kolabCompletionFeedbackSubtitle(partnerName),
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        // Star rating (required)
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = rating != null && i < rating!;
              return IconButton(
                onPressed: () => onRatingChanged(i + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 40,
                  color: filled
                      ? context.colors.primary
                      : context.colors.onSurfaceVariant,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // Optional comment
        TextField(
          controller: commentController,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: l10n.kolabCompletionFeedbackCommentHint,
            filled: true,
            fillColor: context.colors.background,
            border: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide(color: context.colors.darkBorder),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Would Kolab again
        Text(
          l10n.kolabCompletionFeedbackWouldAgain,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: l10n.kolabCompletionFeedbackYes,
                selected: wouldAgain == true,
                onTap: () => onWouldAgainChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceChip(
                label: l10n.kolabCompletionFeedbackNo,
                selected: wouldAgain == false,
                onTap: () => onWouldAgainChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (error != null) ...[
          Text(
            error!,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _PrimaryButton(
          label: isSubmitting
              ? l10n.kolabCompletionFeedbackSubmitting
              : l10n.kolabCompletionFeedbackSubmit,
          isLoading: isSubmitting,
          onTap: isSubmitting ? null : onSubmit,
        ),
        if (onSubmit == null && !isSubmitting) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.kolabCompletionFeedbackTapStar,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
        ],
        if (onFinishLater != null && !isSubmitting) ...[
          const SizedBox(height: 4),
          _SecondaryButton(
            label: l10n.kolabCompletionFeedbackFinishLater,
            onTap: onFinishLater!,
          ),
        ],
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.colors.primary : context.colors.background,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: selected
                ? context.colors.onPrimary
                : context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Step 2 — Celebration
// =============================================================================

class _StepCelebration extends StatelessWidget {
  const _StepCelebration({
    super.key,
    required this.scaleAnimation,
    required this.fadeAnimation,
    required this.baseXp,
    required this.onContinue,
  });

  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;
  final int baseXp;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        ScaleTransition(
          scale: scaleAnimation,
          child: const Text('🎉', style: TextStyle(fontSize: 72)),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: fadeAnimation,
          child: Column(
            children: [
              Text(
                l10n.kolabCompletionCelebrationTitle,
                style: KolabingTextStyles.headlineMedium.copyWith(
                  color: context.colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.kolabCompletionCelebrationBody,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _XpPreviewBadge(baseXp: baseXp),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: l10n.kolabCompletionCelebrationCta,
          onTap: onContinue,
        ),
      ],
    );
  }
}

class _XpPreviewBadge extends StatelessWidget {
  const _XpPreviewBadge({required this.baseXp});
  final int baseXp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const ShapeDecoration(
        color: KolabingColors.primary,
        shape: StadiumBorder(),
      ),
      child: Text(
        AppLocalizations.of(context).kolabCompletionXpEarned(baseXp),
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: KolabingColors.onPrimary,
        ),
      ),
    );
  }
}

// =============================================================================
// Step 2 — Done
// =============================================================================

class _StepDone extends StatelessWidget {
  const _StepDone({super.key, required this.totalXp, required this.onClose});

  final int totalXp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        const Text('🏆', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 24),
        Text(
          l10n.kolabCompletionDoneTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: context.colors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kolabCompletionDoneBody,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primary,
                context.colors.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: KolabingRadius.borderRadiusXl,
          ),
          child: Column(
            children: [
              Text(
                l10n.kolabCompletionDoneXp(totalXp),
                style: KolabingTextStyles.headlineLarge.copyWith(
                  fontSize: 36,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                l10n.kolabCompletionDoneXpLabel,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(label: l10n.kolabCompletionDoneClose, onTap: onClose),
      ],
    );
  }
}

// =============================================================================
// Shared sub-widgets
// =============================================================================

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: onTap != null
              ? KolabingColors.primary
              : context.colors.outlineVariant,
          shape: const StadiumBorder(),
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
            : Text(label, style: KolabingTextStyles.button),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: const ShapeDecoration(
          color: KolabingColors.buttonSecondary,
          shape: StadiumBorder(),
        ),
        child: Text(
          label,
          style: KolabingTextStyles.button.copyWith(
            color: KolabingColors.onButtonSecondary,
          ),
        ),
      ),
    );
  }
}

