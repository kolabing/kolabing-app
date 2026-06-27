import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/constants/radius.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../services/analytics/analytics_service.dart';
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
/// PR 1 (2026-06-26) of the completion-flow simplification: the backend now
/// gates `POST /collaborations/{id}/complete` on a LIGHTWEIGHT completion
/// CONFIRMATION (`POST /collaborations/{id}/completion`, one tap: yes / no /
/// not yet) instead of rich feedback. So this sheet is **confirm-first**:
///   Step 0 — "Did the Kolab happen?" — one tap, yes/no/not yet. POSTs
///            `/completion` immediately (earns XP once, regardless of answer).
///            - 'yes' → also attempts `/complete`.
///            - 'no' / 'not yet' → acknowledges and closes; no `/complete` call.
///   Step 1 — OPTIONAL, SKIPPABLE impact data (star rating + yes/no questions +
///            role-aware metrics), reached after ANY 'yes' answer — whether
///            `/complete` fully succeeded or is still waiting on the partner
///            (QA fix 2026-06-27: previously only the SECOND confirmer ever
///            saw this step; the first lost access to it permanently).
///            POSTs `/feedback` only if the user fills it in; "Skip for now" is
///            always available and does not block completion (it already
///            happened from the caller's side). Whoever skips can come back
///            later from the collaboration detail screen.
///   Step 2 — Celebration + XP preview (only when `/complete` fully succeeded)
///   Step 3 — Done with summary
///   Step 4 — Awaiting-partner / not-ready soft message (the caller's part is
///            done; the Kolab completes once the partner also confirms 'yes').
///            Shown AFTER Step 1 when `/complete` is still pending — and
///            shows the partner's actual answer (no/not_yet) immediately
///            instead of a generic "waiting" message when known.
///
/// `/feedback` is optional impact data — NOT the decoupled public `/review`
/// (the separate, pre-existing star-rating flow). Sending a role-reserved
/// feedback field for the wrong user type is rejected, so the caller's role is
/// resolved from the signed-in user before building that payload.
///
/// Shows [KolabCompletionResult] on close, or null if user dismissed early.
class KolabCompletionSheet extends StatefulWidget {
  const KolabCompletionSheet({
    required this.collaborationId,
    required this.partnerName,
    this.startAtFeedback = false,
    super.key,
  });

  final String collaborationId;
  final String partnerName;

  /// Skip straight to the optional feedback step (Step 1), bypassing the
  /// "did it happen?" question. Used for re-entry from the collaboration
  /// detail screen once the Kolab is already completed (QA fix 2026-06-27
  /// §3) — re-asking an already-answered question would be confusing.
  final bool startAtFeedback;

  static Future<KolabCompletionResult?> show(
    BuildContext context, {
    required String collaborationId,
    required String partnerName,
    bool startAtFeedback = false,
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
        startAtFeedback: startAtFeedback,
      ),
    );
  }

  @override
  State<KolabCompletionSheet> createState() => _KolabCompletionSheetState();
}

class _KolabCompletionSheetState extends State<KolabCompletionSheet>
    with TickerProviderStateMixin {
  late int _step;

  // Resolved once on init: the signed-in user's role decides which feedback
  // fields are allowed (business-only vs community-only).
  bool _isBusiness = false;

  // Step 0 — completion confirmation (yes/no/not_yet). One tap, low friction.
  bool _isConfirming = false;
  String? _confirmError;

  // Step 1 — OPTIONAL impact-data feedback. Submitting POSTs /feedback only;
  // does not gate completion (it already happened by the time this shows).
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

  // Awaiting-partner / not-ready soft message (Step 4) — covers both "partner
  // hasn't confirmed yet" and "no/not_yet acknowledged" cases.
  String? _awaitingPartnerMessage;
  String? _awaitingPartnerTitleOverride;

  // Result tracking
  Collaboration? _updatedCollaboration;

  /// Whether `/complete` actually flipped the collaboration to `completed`
  /// during this session. False when the caller said 'yes' but the gate is
  /// still waiting on the partner (or the partner answered no/not_yet) —
  /// the optional feedback step (Step 1) is shown either way (QA fix
  /// 2026-06-27: the first confirmer used to lose access to it entirely).
  bool _completeSucceeded = false;

  static const int _confirmXp = 10;
  static const int _feedbackXp = 10;
  int _xpEarned = 0;

  late final AnimationController _celebrationController;
  late final AnimationController _xpCountController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _step = widget.startAtFeedback ? 1 : 0;
    // The Kolab is already completed when re-entering straight to feedback —
    // skip/submit should land on the celebration step, not awaiting-partner.
    _completeSucceeded = widget.startAtFeedback;
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

  /// Step 0 → one tap. Submits the lightweight completion confirmation
  /// immediately (earns XP once, regardless of answer), then:
  /// - `'yes'` also attempts `/complete`, then ALWAYS advances to the
  ///   optional feedback step (Step 1) — whether or not `/complete` fully
  ///   succeeded. QA fix (2026-06-27): previously, whichever party confirmed
  ///   FIRST skipped straight to the awaiting-partner step and never saw the
  ///   optional feedback screen at all. Now both confirmers reach it; the
  ///   awaiting-partner / not-ready message (if any) is shown AFTER Step 1,
  ///   not instead of it.
  /// - `'no'` / `'not_yet'` acknowledges and stops — no `/complete` call, no
  ///   feedback offered (nothing happened yet to give feedback about).
  Future<void> _onConfirm(String status) async {
    setState(() {
      _isConfirming = true;
      _confirmError = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      await submitCollaborationCompletion(widget.collaborationId, status: status);
      _xpEarned += _confirmXp;

      if (status != 'yes') {
        if (!mounted) return;
        setState(() {
          _isConfirming = false;
          _awaitingPartnerTitleOverride = status == 'no'
              ? l10n.kolabCompletionConfirmedNoTitle
              : l10n.kolabCompletionConfirmedNotYetTitle;
          _awaitingPartnerMessage = status == 'no'
              ? l10n.kolabCompletionConfirmedNoBody
              : l10n.kolabCompletionConfirmedNotYetBody;
          _step = 4;
        });
        HapticFeedback.lightImpact();
        return;
      }

      // 'yes' — try to complete. Whatever happens, Step 1 (optional
      // feedback) comes next; only the EVENTUAL destination (celebration vs.
      // awaiting-partner) depends on the outcome, decided in
      // _goToCelebration() via `_completeSucceeded`.
      try {
        final collab = await markCollaborationCompleted(widget.collaborationId);
        _updatedCollaboration = collab;
        _completeSucceeded = true;
      } on CollaborationCompletionException catch (e) {
        _completeSucceeded = false;
        _setAwaitingCopyFor(e, l10n);
      }

      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _step = 1; // optional, skippable impact data — reachable either way
      });
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isConfirming = false;
        _confirmError = l10n.kolabCompletionConfirmError;
      });
    }
  }

  /// Resolve the awaiting-partner copy for Step 4 from a failed `/complete`
  /// call. Mirrors the partner-status-aware copy on the detail screen (QA
  /// fix 2026-06-27): if the partner already answered no/not_yet, say so
  /// immediately instead of a generic "waiting" message.
  void _setAwaitingCopyFor(CollaborationCompletionException e, AppLocalizations l10n) {
    switch (e.errorCode) {
      case CollaborationCompletionErrorCode.completionNotConfirmed:
        switch (e.partnerStatus) {
          case 'no':
            _awaitingPartnerTitleOverride =
                l10n.collaborationDetailPartnerSaidNoTitle(widget.partnerName);
            _awaitingPartnerMessage =
                l10n.collaborationDetailPartnerSaidNoBody(widget.partnerName);
          case 'not_yet':
            _awaitingPartnerTitleOverride =
                l10n.collaborationDetailPartnerSaidNotYetTitle(widget.partnerName);
            _awaitingPartnerMessage =
                l10n.collaborationDetailPartnerSaidNotYetBody(widget.partnerName);
          default:
            _awaitingPartnerTitleOverride = null;
            _awaitingPartnerMessage =
                l10n.kolabCompletionAwaitingPartnerBody(widget.partnerName);
        }
      case CollaborationCompletionErrorCode.awaitingPartnerCompletionConfirmation:
        _awaitingPartnerTitleOverride = null;
        _awaitingPartnerMessage =
            l10n.kolabCompletionAwaitingPartnerBody(widget.partnerName);
      case CollaborationCompletionErrorCode.cannotComplete:
      case CollaborationCompletionErrorCode.invalidStatusTransition:
        // Most likely the partner already completed it via their own flow.
        _awaitingPartnerTitleOverride = null;
        _awaitingPartnerMessage = l10n.kolabCompletionAlreadyCompleted;
        // Already done — treat as a full success for the celebration step.
        _completeSucceeded = true;
      default:
        // Unexpected, but the caller's own confirmation already succeeded —
        // don't strand them; fall back to a generic waiting message rather
        // than reopening Step 0.
        _awaitingPartnerTitleOverride = null;
        _awaitingPartnerMessage =
            l10n.kolabCompletionAwaitingPartnerBody(widget.partnerName);
    }
  }

  /// Step 1 (optional) → submit impact-data feedback. Does not affect
  /// completion — the Kolab is already complete by the time this shows.
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

      unawaited(
        AnalyticsService.instance.capture(
          AnalyticsEvents.feedbackSubmitted,
          properties: {
            'collaboration_id': widget.collaborationId,
            'rating': rating,
          },
        ),
      );

      _xpEarned += _feedbackXp;
      _goToCelebration();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _feedbackError = l10n.kolabCompletionSheetFeedbackError;
      });
    }
  }

  /// Skip the optional feedback step — the user's completion answer already
  /// went through regardless of this step.
  void _onSkipFeedback() => _goToCelebration();

  /// Advance past the optional feedback step to whichever destination fits:
  /// celebration if `/complete` already succeeded, or the awaiting-partner /
  /// not-ready message if it's still pending on the partner.
  void _goToCelebration() {
    if (!mounted) return;
    if (_completeSucceeded) {
      setState(() {
        _isSubmitting = false;
        _step = 2;
      });
      _celebrationController.forward();
    } else {
      setState(() {
        _isSubmitting = false;
        _step = 4;
      });
      HapticFeedback.lightImpact();
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
        totalXpEarned: _xpEarned,
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
          isSubmitting: _isConfirming,
          error: _confirmError,
          onConfirm: _onConfirm,
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
          onSkip: _isSubmitting ? null : _onSkipFeedback,
        );
      case 2:
        return _StepCelebration(
          key: const ValueKey(2),
          scaleAnimation: _scaleAnimation,
          fadeAnimation: _fadeAnimation,
          baseXp: _xpEarned,
          onContinue: _goToDone,
        );
      case 3:
        return _StepDone(
          key: const ValueKey(3),
          totalXp: _xpEarned,
          onClose: _close,
        );
      case 4:
        return _StepAwaitingPartner(
          key: const ValueKey(4),
          title: _awaitingPartnerTitleOverride,
          message: _awaitingPartnerMessage ?? '',
          xpEarned: _xpEarned,
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

/// Step 0 — one-tap, required completion confirmation (yes/no/not_yet).
/// PR 1 (2026-06-26): this replaces the old required-feedback gate. Tapping
/// any option immediately POSTs `/completion` (earns XP once, regardless of
/// the answer) — there is no separate "confirm" step after choosing.
class _StepConfirm extends StatelessWidget {
  const _StepConfirm({
    super.key,
    required this.partnerName,
    required this.isSubmitting,
    required this.error,
    required this.onConfirm,
  });

  final String partnerName;
  final bool isSubmitting;
  final String? error;
  final ValueChanged<String> onConfirm;

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
        if (isSubmitting)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.kolabCompletionConfirmLoading,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          _PrimaryButton(
            label: l10n.kolabCompletionConfirmCta,
            onTap: () => onConfirm('yes'),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                label: l10n.kolabCompletionConfirmDismiss,
                onTap: isSubmitting ? null : () => onConfirm('not_yet'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryButton(
                label: l10n.kolabCompletionConfirmNo,
                onTap: isSubmitting ? null : () => onConfirm('no'),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
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
    required this.onSkip,
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

  /// Skip this optional step entirely — completion already happened.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kolabCompletionFeedbackOptionalTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            fontSize: 22,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kolabCompletionFeedbackOptionalSubtitle(partnerName),
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
        const SizedBox(height: 12),
        _SecondaryButton(
          label: l10n.kolabCompletionFeedbackSkip,
          onTap: onSkip,
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
    this.title,
    required this.message,
    required this.xpEarned,
    required this.onClose,
  });

  /// Overrides the default "Your feedback is in" title — used for the
  /// no/not_yet acknowledgement copy.
  final String? title;
  final String message;
  final int xpEarned;
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
          title ?? l10n.kolabCompletionAwaitingPartnerTitle,
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
        if (xpEarned > 0) ...[
          const SizedBox(height: 16),
          _XpPreviewBadge(baseXp: xpEarned),
        ],
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
  Widget build(BuildContext context) => KolabingButton(
        label: label,
        onPressed: onTap,
        variant: KolabingButtonVariant.primary,
        isLoading: isLoading,
        isDisabled: onTap == null && !isLoading,
      );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => KolabingButton(
        label: label,
        onPressed: onTap,
        variant: KolabingButtonVariant.secondary,
        size: KolabingButtonSize.compact,
        isDisabled: onTap == null,
      );
}

