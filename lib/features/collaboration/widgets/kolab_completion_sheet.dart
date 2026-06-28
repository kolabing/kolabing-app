import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/constants/radius.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
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

  // Step 1 — OPTIONAL 5-star Kolab review. Submitting POSTs /review only;
  // does not gate completion (it already happened by the time this shows).
  int? _communicationRating;
  int? _reliabilityRating;
  int? _fitRating;
  int? _valueRating;
  int? _repeatRating;
  final _commentController = TextEditingController();
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
    _commentController.dispose();
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
      await submitCollaborationCompletion(
        widget.collaborationId,
        status: status,
      );
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
  void _setAwaitingCopyFor(
    CollaborationCompletionException e,
    AppLocalizations l10n,
  ) {
    switch (e.errorCode) {
      case CollaborationCompletionErrorCode.completionNotConfirmed:
        switch (e.partnerStatus) {
          case 'no':
            _awaitingPartnerTitleOverride = l10n
                .collaborationDetailPartnerSaidNoTitle(widget.partnerName);
            _awaitingPartnerMessage = l10n.collaborationDetailPartnerSaidNoBody(
              widget.partnerName,
            );
          case 'not_yet':
            _awaitingPartnerTitleOverride = l10n
                .collaborationDetailPartnerSaidNotYetTitle(widget.partnerName);
            _awaitingPartnerMessage = l10n
                .collaborationDetailPartnerSaidNotYetBody(widget.partnerName);
          default:
            _awaitingPartnerTitleOverride = null;
            _awaitingPartnerMessage = l10n.kolabCompletionAwaitingPartnerBody(
              widget.partnerName,
            );
        }
      case CollaborationCompletionErrorCode
          .awaitingPartnerCompletionConfirmation:
        _awaitingPartnerTitleOverride = null;
        _awaitingPartnerMessage = l10n.kolabCompletionAwaitingPartnerBody(
          widget.partnerName,
        );
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
        _awaitingPartnerMessage = l10n.kolabCompletionAwaitingPartnerBody(
          widget.partnerName,
        );
    }
  }

  /// Step 1 (optional) → submit the 5-star Kolab review. Does not affect
  /// completion — the Kolab is already complete by the time this shows.
  Future<void> _onSubmitFeedback() async {
    final communication = _communicationRating;
    final reliability = _reliabilityRating;
    final fit = _fitRating;
    final value = _valueRating;
    final repeat = _repeatRating;
    if (communication == null ||
        reliability == null ||
        fit == null ||
        value == null ||
        repeat == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackError = null;
    });

    final l10n = AppLocalizations.of(context);

    try {
      await submitCollaborationReview(
        widget.collaborationId,
        communicationRating: communication,
        reliabilityRating: reliability,
        fitRating: fit,
        valueRating: value,
        repeatRating: repeat,
        publicComment: _commentController.text,
      );

      _xpEarned += _feedbackXp;
      _goToCelebration();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _feedbackError = l10n.kolabStarReviewError;
      });
    }
  }

  /// Skip the optional review step — the user's completion answer already
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

  void _goToDone() => setState(() => _step = 3);

  void _close() {
    if (_updatedCollaboration != null) {
      Navigator.of(context).pop(
        KolabCompletionResult(
          collaboration: _updatedCollaboration!,
          totalXpEarned: _xpEarned,
        ),
      );
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KolabingRadius.xl),
        ),
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
        final canSubmit =
            _communicationRating != null &&
            _reliabilityRating != null &&
            _fitRating != null &&
            _valueRating != null &&
            _repeatRating != null;
        return _StepStarReview(
          key: const ValueKey(1),
          partnerName: widget.partnerName,
          isBusiness: _isBusiness,
          communicationRating: _communicationRating,
          reliabilityRating: _reliabilityRating,
          fitRating: _fitRating,
          valueRating: _valueRating,
          repeatRating: _repeatRating,
          commentController: _commentController,
          isSubmitting: _isSubmitting,
          error: _feedbackError,
          onCommunicationChanged: (v) =>
              setState(() => _communicationRating = v),
          onReliabilityChanged: (v) => setState(() => _reliabilityRating = v),
          onFitChanged: (v) => setState(() => _fitRating = v),
          onValueChanged: (v) => setState(() => _valueRating = v),
          onRepeatChanged: (v) => setState(() => _repeatRating = v),
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
// Step 1 — Optional 5-star Kolab review
// =============================================================================

/// Role-specific label + helper text for one of the five rating rows.
class _StarRatingRowSpec {
  const _StarRatingRowSpec({required this.label, required this.helper});
  final String label;
  final String helper;
}

class _StepStarReview extends StatelessWidget {
  const _StepStarReview({
    super.key,
    required this.partnerName,
    required this.isBusiness,
    required this.communicationRating,
    required this.reliabilityRating,
    required this.fitRating,
    required this.valueRating,
    required this.repeatRating,
    required this.commentController,
    required this.isSubmitting,
    required this.error,
    required this.onCommunicationChanged,
    required this.onReliabilityChanged,
    required this.onFitChanged,
    required this.onValueChanged,
    required this.onRepeatChanged,
    required this.onSubmit,
    required this.onSkip,
  });

  final String partnerName;
  final bool isBusiness;
  final int? communicationRating;
  final int? reliabilityRating;
  final int? fitRating;
  final int? valueRating;
  final int? repeatRating;
  final TextEditingController commentController;
  final bool isSubmitting;
  final String? error;
  final ValueChanged<int> onCommunicationChanged;
  final ValueChanged<int> onReliabilityChanged;
  final ValueChanged<int> onFitChanged;
  final ValueChanged<int> onValueChanged;
  final ValueChanged<int> onRepeatChanged;
  final VoidCallback? onSubmit;

  /// Skip this optional step entirely — completion already happened.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final rows = isBusiness
        ? [
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewBizCommunicationLabel,
              helper: l10n.kolabStarReviewBizCommunicationHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewBizReliabilityLabel,
              helper: l10n.kolabStarReviewBizReliabilityHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewBizFitLabel,
              helper: l10n.kolabStarReviewBizFitHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewBizValueLabel,
              helper: l10n.kolabStarReviewBizValueHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewBizRepeatLabel,
              helper: l10n.kolabStarReviewBizRepeatHelper,
            ),
          ]
        : [
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewComCommunicationLabel,
              helper: l10n.kolabStarReviewComCommunicationHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewComReliabilityLabel,
              helper: l10n.kolabStarReviewComReliabilityHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewComFitLabel,
              helper: l10n.kolabStarReviewComFitHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewComValueLabel,
              helper: l10n.kolabStarReviewComValueHelper,
            ),
            _StarRatingRowSpec(
              label: l10n.kolabStarReviewComRepeatLabel,
              helper: l10n.kolabStarReviewComRepeatHelper,
            ),
          ];

    final ratings = [
      communicationRating,
      reliabilityRating,
      fitRating,
      valueRating,
      repeatRating,
    ];
    final onChanged = [
      onCommunicationChanged,
      onReliabilityChanged,
      onFitChanged,
      onValueChanged,
      onRepeatChanged,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kolabStarReviewTitle,
          style: KolabingTextStyles.headlineMedium.copyWith(
            fontSize: 22,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kolabStarReviewSubtitle(partnerName),
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _StarRatingRow(
            spec: rows[i],
            rating: ratings[i],
            onChanged: onChanged[i],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.kolabStarReviewCommentLabel,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: commentController,
          maxLines: 3,
          maxLength: 2000,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
              borderSide: BorderSide(color: context.colors.darkBorder),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
              ? l10n.kolabStarReviewSubmitting
              : l10n.kolabStarReviewSubmit,
          isLoading: isSubmitting,
          onTap: isSubmitting ? null : onSubmit,
        ),
        const SizedBox(height: 12),
        _SecondaryButton(label: l10n.kolabStarReviewSkip, onTap: onSkip),
      ],
    );
  }
}

/// One labelled row of 5 tappable stars, with helper text underneath the
/// label and the stars right-aligned in a clean card-like row.
class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({
    required this.spec,
    required this.rating,
    required this.onChanged,
  });

  final _StarRatingRowSpec spec;
  final int? rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.label,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            spec.helper,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final filled = rating != null && i < rating!;
              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 30,
                    color: filled
                        ? KolabingColors.primary
                        : context.colors.onSurfaceVariant,
                  ),
                ),
              );
            }),
          ),
        ],
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
