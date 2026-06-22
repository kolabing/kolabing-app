import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/constants/radius.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../models/collaboration.dart';
import '../providers/collaboration_detail_provider.dart';

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
/// The backend enforces a FEEDBACK GATE: `POST /collaborations/{id}/complete`
/// only succeeds once BOTH participant user types have POSTed
/// `POST /collaborations/{id}/feedback`. So this sheet is **feedback-first**:
///   Step 0 — "Did the Kolab happen?" confirmation (notes the mutual rule)
///   Step 1 — **Required feedback** (rating + expectation-match +
///            would-recommend, all required; plus optional role-aware metrics)
///            → POSTs `/feedback`, THEN POSTs `/complete`
///   Step 2 — Celebration + XP preview (only on full `/complete` success)
///   Step 3 — Done with summary
///   Step 4 — Awaiting-partner SOFT SUCCESS (the caller's part is done; the
///            Kolab completes once the partner confirms too)
///
/// `/feedback` is the gate endpoint — NOT the decoupled public `/review` (which
/// remains the separate post-completion "leave a review" flow). Sending a
/// role-reserved field for the wrong user type is rejected, so the caller's role
/// is resolved from the signed-in user before building the payload.
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

  // Resolved once on init: the signed-in user's role decides which feedback
  // fields are allowed (business-only vs community-only).
  bool _isBusiness = false;

  // Required-feedback step state. Submitting POSTs /feedback THEN /complete.
  int? _rating;
  bool? _expectationMatch;
  bool? _wouldRecommend;
  bool? _wouldCollaborateAgain;
  final _postsReelsController = TextEditingController();
  final _storiesController = TextEditingController(); // business only
  final _revenueController = TextEditingController(); // business only
  final _benefitsController = TextEditingController(); // community only
  bool _isSubmitting = false;
  String? _feedbackError;

  // Awaiting-partner soft-success copy (Step 4).
  String? _awaitingPartnerMessage;

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
    // Resolve the caller's role for the role-aware feedback payload.
    AuthService().getStoredUser().then((user) {
      if (!mounted) return;
      setState(() => _isBusiness = user?.userType == UserType.business);
    });
  }

  @override
  void dispose() {
    _postsReelsController.dispose();
    _storiesController.dispose();
    _revenueController.dispose();
    _benefitsController.dispose();
    _celebrationController.dispose();
    _xpCountController.dispose();
    super.dispose();
  }

  /// Step 0 → advances straight to the REQUIRED feedback step. No network call
  /// here: completion is gated on feedback, so we collect feedback first.
  void _onConfirmComplete() => setState(() => _step = 1);

  /// Step 1 → submit feedback (`/feedback`), THEN attempt `/complete`, branching
  /// on the backend `error_code`. Rating + expectation-match + would-recommend
  /// are required; the optional role-aware metrics are sent when filled.
  Future<void> _onSubmitFeedback() async {
    final rating = _rating;
    final expectationMatch = _expectationMatch;
    final wouldRecommend = _wouldRecommend;
    final wouldCollaborateAgain = _wouldCollaborateAgain;
    if (rating == null ||
        expectationMatch == null ||
        wouldRecommend == null ||
        wouldCollaborateAgain == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackError = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      // 1) Satisfy the gate: POST /feedback with the role-aware payload.
      await submitCollaborationFeedback(
        widget.collaborationId,
        isBusiness: _isBusiness,
        rating: rating,
        expectationMatch: expectationMatch,
        wouldRecommend: wouldRecommend,
        wouldCollaborateAgain: wouldCollaborateAgain,
        postsReels: _parseInt(_postsReelsController.text),
        storiesPosted: _isBusiness ? _parseInt(_storiesController.text) : null,
        revenue: _isBusiness ? _parseNum(_revenueController.text) : null,
        benefits: _isBusiness ? null : _benefitsController.text,
      );

      // 2) Now try to complete — the gate may still be waiting on the partner.
      final collab = await markCollaborationCompleted(widget.collaborationId);
      _updatedCollaboration = collab;
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _step = 2; // celebration
      });
      _celebrationController.forward();
      HapticFeedback.mediumImpact();
    } on CollaborationCompletionException catch (e) {
      if (!mounted) return;
      switch (e.errorCode) {
        case CollaborationCompletionErrorCode.awaitingPartnerFeedback:
          // SOFT SUCCESS — our part is done; close with a friendly message.
          setState(() {
            _isSubmitting = false;
            _awaitingPartnerMessage =
                l10n.kolabCompletionAwaitingPartnerBody(widget.partnerName);
            _step = 4; // awaiting-partner soft success
          });
          HapticFeedback.lightImpact();
        case CollaborationCompletionErrorCode.cannotComplete:
        case CollaborationCompletionErrorCode.invalidStatusTransition:
          // Most likely the partner already completed it → treat as completed.
          setState(() {
            _isSubmitting = false;
            _awaitingPartnerMessage = l10n.kolabCompletionAlreadyCompleted;
            _step = 4;
          });
        case CollaborationCompletionErrorCode.awaitingOwnFeedback:
        default:
          // Shouldn't happen (we just submitted) — keep the form open with the
          // backend message so the user can retry.
          setState(() {
            _isSubmitting = false;
            _feedbackError = e.message;
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _feedbackError = l10n.kolabCompletionSheetFeedbackError;
      });
    }
  }

  int? _parseInt(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  num? _parseNum(String raw) {
    final v = raw.trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    return num.tryParse(v);
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
          onConfirm: _onConfirmComplete,
          onDismiss: _close,
        );
      case 1:
        final canSubmit = _rating != null &&
            _expectationMatch != null &&
            _wouldRecommend != null &&
            _wouldCollaborateAgain != null;
        return _StepFeedback(
          key: const ValueKey(1),
          partnerName: widget.partnerName,
          isBusiness: _isBusiness,
          rating: _rating,
          expectationMatch: _expectationMatch,
          wouldRecommend: _wouldRecommend,
          wouldCollaborateAgain: _wouldCollaborateAgain,
          postsReelsController: _postsReelsController,
          storiesController: _storiesController,
          revenueController: _revenueController,
          benefitsController: _benefitsController,
          isSubmitting: _isSubmitting,
          error: _feedbackError,
          onRatingChanged: (v) => setState(() => _rating = v),
          onExpectationChanged: (v) => setState(() => _expectationMatch = v),
          onRecommendChanged: (v) => setState(() => _wouldRecommend = v),
          onCollaborateAgainChanged: (v) =>
              setState(() => _wouldCollaborateAgain = v),
          onSubmit: canSubmit ? _onSubmitFeedback : null,
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
      case 4:
        return _StepAwaitingPartner(
          key: const ValueKey(4),
          message: _awaitingPartnerMessage ?? '',
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
    required this.onConfirm,
    required this.onDismiss,
  });

  final String partnerName;
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
        const SizedBox(height: 16),
        // Make the mutual feedback requirement explicit.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(color: context.colors.darkBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 18,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.kolabCompletionConfirmMutualNote(partnerName),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: context.colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: l10n.kolabCompletionConfirmCta,
          onTap: onConfirm,
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
    required this.isBusiness,
    required this.rating,
    required this.expectationMatch,
    required this.wouldRecommend,
    required this.wouldCollaborateAgain,
    required this.postsReelsController,
    required this.storiesController,
    required this.revenueController,
    required this.benefitsController,
    required this.isSubmitting,
    required this.error,
    required this.onRatingChanged,
    required this.onExpectationChanged,
    required this.onRecommendChanged,
    required this.onCollaborateAgainChanged,
    required this.onSubmit,
  });

  final String partnerName;
  final bool isBusiness;
  final int? rating;
  final bool? expectationMatch;
  final bool? wouldRecommend;
  final bool? wouldCollaborateAgain;
  final TextEditingController postsReelsController;
  final TextEditingController storiesController;
  final TextEditingController revenueController;
  final TextEditingController benefitsController;
  final bool isSubmitting;
  final String? error;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<bool> onExpectationChanged;
  final ValueChanged<bool> onRecommendChanged;
  final ValueChanged<bool> onCollaborateAgainChanged;
  final VoidCallback? onSubmit;

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
        // Expectation match (required yes/no)
        _YesNoQuestion(
          label: l10n.kolabCompletionFeedbackExpectationMatch,
          value: expectationMatch,
          onChanged: onExpectationChanged,
          yesLabel: l10n.kolabCompletionFeedbackYes,
          noLabel: l10n.kolabCompletionFeedbackNo,
        ),
        const SizedBox(height: 16),
        // Would recommend (required yes/no)
        _YesNoQuestion(
          label: l10n.kolabCompletionFeedbackWouldRecommend,
          value: wouldRecommend,
          onChanged: onRecommendChanged,
          yesLabel: l10n.kolabCompletionFeedbackYes,
          noLabel: l10n.kolabCompletionFeedbackNo,
        ),
        const SizedBox(height: 16),
        // Would kolab again (required yes/no). This feedback now BECOMES the
        // public review (backend auto-mirrors it), so we no longer ask the user
        // to leave a separate review post-completion.
        _YesNoQuestion(
          label: l10n.kolabCompletionFeedbackWouldCollaborateAgain,
          value: wouldCollaborateAgain,
          onChanged: onCollaborateAgainChanged,
          yesLabel: l10n.kolabCompletionFeedbackYes,
          noLabel: l10n.kolabCompletionFeedbackNo,
        ),
        const SizedBox(height: 20),
        // Optional, role-aware metrics
        Text(
          l10n.kolabCompletionFeedbackMetricsOptional,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _MetricField(
          controller: postsReelsController,
          label: l10n.kolabCompletionFeedbackPostsReels,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        if (isBusiness) ...[
          const SizedBox(height: 8),
          _MetricField(
            controller: storiesController,
            label: l10n.kolabCompletionFeedbackStoriesPosted,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          _MetricField(
            controller: revenueController,
            label: l10n.kolabCompletionFeedbackRevenue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ] else ...[
          const SizedBox(height: 8),
          _MetricField(
            controller: benefitsController,
            label: l10n.kolabCompletionFeedbackBenefits,
            maxLines: 3,
            maxLength: 2000,
          ),
        ],
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
      ],
    );
  }
}

/// A required yes/no question rendered as a labelled pair of choice chips.
class _YesNoQuestion extends StatelessWidget {
  const _YesNoQuestion({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.yesLabel,
    required this.noLabel,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool> onChanged;
  final String yesLabel;
  final String noLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
                label: yesLabel,
                selected: value == true,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceChip(
                label: noLabel,
                selected: value == false,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A compact, optional metric text field used in the feedback form.
class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: context.colors.background,
        border: OutlineInputBorder(
          borderRadius: KolabingRadius.borderRadiusMd,
          borderSide: BorderSide(color: context.colors.darkBorder),
        ),
      ),
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
// Step 4 — Awaiting partner (soft success)
// =============================================================================

class _StepAwaitingPartner extends StatelessWidget {
  const _StepAwaitingPartner({
    super.key,
    required this.message,
    required this.onClose,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        const Text('🤝', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text(
          l10n.kolabCompletionAwaitingPartnerTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            color: context.colors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: l10n.kolabCompletionAwaitingPartnerClose,
          onTap: onClose,
        ),
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

