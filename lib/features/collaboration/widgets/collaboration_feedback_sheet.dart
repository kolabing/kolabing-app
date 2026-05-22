import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../models/collaboration_feedback.dart';
import '../providers/collaboration_feedback_provider.dart';

/// Multi-step bottom sheet that collects feedback from EITHER side of a
/// collaboration. Each step is one question; required questions gate the Next
/// button. The [variant] tailors copy + which optional questions appear
/// (business vs community, see `docs/ROLES-AND-PERMISSIONS.md` §4).
///
/// Two entry points:
/// - [show]: standalone post-completion survey that submits on its own (the
///   "Leave review" CTA path). Returns true when submitted.
/// - [collectForFinish]: collects + validates the draft but does NOT submit;
///   returns the completed draft so the caller can finish + submit feedback in
///   one `POST /finish` call. Returns null if the user backs out.
class CollaborationFeedbackSheet extends StatefulWidget {
  const CollaborationFeedbackSheet({
    required this.collaborationId,
    this.variant = FeedbackVariant.business,
    this.submitOnComplete = true,
    super.key,
  });

  final String collaborationId;

  /// Which side is leaving feedback.
  final FeedbackVariant variant;

  /// When true (default), the sheet submits the survey itself via
  /// [submitCollaborationFeedback]. When false, it returns the completed draft
  /// to the caller without any network call (used by the finish flow, which
  /// submits feedback + finish together).
  final bool submitOnComplete;

  /// Returns `true` when the survey was submitted successfully, `false` if
  /// the user dismissed without finishing.
  static Future<bool> show(
    BuildContext context, {
    required String collaborationId,
    FeedbackVariant variant = FeedbackVariant.business,
  }) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => CollaborationFeedbackSheet(
        collaborationId: collaborationId,
        variant: variant,
      ),
    );
    return result == true;
  }

  /// Collect the feedback without submitting. Returns the completed draft, or
  /// null if the user dismissed. The caller is responsible for submitting it
  /// (e.g. via `finishCollaborationWithFeedback`).
  static Future<CollaborationFeedbackDraft?> collectForFinish(
    BuildContext context, {
    required String collaborationId,
    required FeedbackVariant variant,
  }) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => CollaborationFeedbackSheet(
        collaborationId: collaborationId,
        variant: variant,
        submitOnComplete: false,
      ),
    );
    return result is CollaborationFeedbackDraft ? result : null;
  }

  @override
  State<CollaborationFeedbackSheet> createState() =>
      _CollaborationFeedbackSheetState();
}

/// Identifies each possible question so the step order can vary by variant.
enum _FbStep {
  star,
  stories, // business only
  postsReels,
  revenue, // business only
  benefits, // community only
  expectations,
  recommend,
  review,
}

class _CollaborationFeedbackSheetState
    extends State<CollaborationFeedbackSheet> {
  final _pageController = PageController();
  int _stepIndex = 0;
  late CollaborationFeedbackDraft _draft;
  late final List<_FbStep> _steps;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _draft = CollaborationFeedbackDraft(variant: widget.variant);
    // Build the step order for this variant. Required steps (star, recommend,
    // review) are shared; the rest are optional and variant-specific.
    _steps = widget.variant.isBusiness
        ? const [
            _FbStep.star,
            _FbStep.stories,
            _FbStep.postsReels,
            _FbStep.revenue,
            _FbStep.expectations,
            _FbStep.recommend,
            _FbStep.review,
          ]
        : const [
            _FbStep.star,
            _FbStep.benefits,
            _FbStep.postsReels,
            _FbStep.expectations,
            _FbStep.recommend,
            _FbStep.review,
          ];
  }

  int get _stepCount => _steps.length;
  _FbStep get _currentStep => _steps[_stepIndex];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_currentStep) {
      case _FbStep.star:
        return _draft.starRating != null;
      case _FbStep.recommend:
        return _draft.wouldRecommend != null;
      case _FbStep.benefits:
        // Required for community: the backend `benefits` field is mandatory.
        return _draft.hasValidBenefits;
      case _FbStep.review:
        return _draft.canSubmit && !_isSubmitting;
      default:
        // Optional steps: always advanceable (Next / Skip).
        return true;
    }
  }

  String get _nextLabel {
    if (_stepIndex == _stepCount - 1) {
      return widget.submitOnComplete ? 'SUBMIT FEEDBACK' : 'FINISH & SUBMIT';
    }
    if (_isOptionalStep(_currentStep)) {
      return _isStepAnswered(_currentStep) ? 'NEXT' : 'SKIP';
    }
    return 'NEXT';
  }

  bool _isOptionalStep(_FbStep step) =>
      step != _FbStep.star &&
      step != _FbStep.recommend &&
      step != _FbStep.benefits &&
      step != _FbStep.review;

  bool _isStepAnswered(_FbStep step) {
    switch (step) {
      case _FbStep.stories:
        return _draft.storiesPosted != null;
      case _FbStep.postsReels:
        return _draft.postsReels != null;
      case _FbStep.revenue:
        return _draft.revenueAmountCents != null || _draft.revenueSkipped;
      case _FbStep.benefits:
        return _draft.hasValidBenefits;
      case _FbStep.expectations:
        return _draft.metExpectationsRating != null ||
            (_draft.metExpectationsComment?.trim().isNotEmpty ?? false);
      default:
        return false;
    }
  }

  void _goNext() {
    if (_stepIndex == _stepCount - 1) {
      _submit();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _stepIndex++);
    _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _goBack() {
    if (_stepIndex == 0) {
      _confirmDismiss();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _stepIndex--);
    _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmDismiss() async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldDismiss = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Skip feedback?',
          style: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'You can always leave a review later from the Kolab page.',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep going',
              style: GoogleFonts.dmSans(color: KolabingColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Skip',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldDismiss ?? false) {
      messenger.hideCurrentSnackBar();
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _submit() async {
    if (!_draft.canSubmit) return;

    // Finish flow: don't submit here — hand the completed draft back to the
    // caller, which finishes the collaboration and submits feedback together.
    if (!widget.submitOnComplete) {
      Navigator.of(context).pop(_draft);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await submitCollaborationFeedback(widget.collaborationId, _draft);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FeedbackEndpointMissingException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved locally — backend pending.',
            style: GoogleFonts.openSans(color: Colors.white),
          ),
          backgroundColor: KolabingColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not send feedback: $e',
            style: GoogleFonts.openSans(color: Colors.white),
          ),
          backgroundColor: KolabingColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Map a step identifier to its page widget. Wiring matches the variant's
  /// step list built in [initState].
  Widget _buildStep(_FbStep step) {
    switch (step) {
      case _FbStep.star:
        return _StarRatingStep(
          value: _draft.starRating,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(starRating: value)),
        );
      case _FbStep.stories:
        return _BucketStep(
          title: 'How many stories did they post?',
          subtitle: 'Stories on Instagram / TikTok / Snap during the campaign.',
          value: _draft.storiesPosted,
          onChanged: (value) => setState(
            () => _draft = _draft.copyWith(
              storiesPosted: value,
              clearStoriesPosted: value == null,
            ),
          ),
        );
      case _FbStep.postsReels:
        return _BucketStep(
          title: widget.variant.isBusiness
              ? 'How many posts or reels did they publish?'
              : 'How many posts or reels did you publish?',
          subtitle: 'Permanent feed content — posts, reels, TikToks.',
          value: _draft.postsReels,
          onChanged: (value) => setState(
            () => _draft = _draft.copyWith(
              postsReels: value,
              clearPostsReels: value == null,
            ),
          ),
        );
      case _FbStep.revenue:
        return _RevenueStep(
          amountCents: _draft.revenueAmountCents,
          skipped: _draft.revenueSkipped,
          onChanged: (int? amount, {required bool skipped}) => setState(
            () => _draft = _draft.copyWith(
              revenueAmountCents: amount,
              revenueSkipped: skipped,
              clearRevenueAmount: amount == null,
            ),
          ),
        );
      case _FbStep.benefits:
        return _BenefitsStep(
          selected: _draft.benefits,
          otherText: _draft.benefitsOther,
          onChanged: (selected, otherText) => setState(
            () => _draft = _draft.copyWith(
              benefits: selected,
              benefitsOther: otherText,
              clearBenefitsOther: otherText == null,
            ),
          ),
        );
      case _FbStep.expectations:
        return _ExpectationsStep(
          rating: _draft.metExpectationsRating,
          comment: _draft.metExpectationsComment,
          onChanged: (rating, comment) => setState(
            () => _draft = _draft.copyWith(
              metExpectationsRating: rating,
              metExpectationsComment: comment,
              clearMetExpectationsRating: rating == null,
              clearMetExpectationsComment: comment == null,
            ),
          ),
        );
      case _FbStep.recommend:
        return _RecommendStep(
          variant: widget.variant,
          value: _draft.wouldRecommend,
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(wouldRecommend: value)),
        );
      case _FbStep.review:
        return _ReviewStep(draft: _draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.9;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmDismiss();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: KolabingColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              _ProgressBar(stepIndex: _stepIndex, total: _stepCount),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isSubmitted ? null : _goBack,
                      icon: const Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: KolabingColors.textPrimary,
                      ),
                      tooltip: _stepIndex == 0 ? 'Close' : 'Back',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Step ${_stepIndex + 1} of $_stepCount',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textTertiary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: _isSubmitted
                    ? const _ThankYouState()
                    : PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _steps.map(_buildStep).toList(),
                      ),
              ),
              if (!_isSubmitted)
                _FooterButton(
                  label: _nextLabel,
                  enabled: _canAdvance,
                  loading: _isSubmitting,
                  onTap: _goNext,
                  bottomPadding: mediaQuery.padding.bottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Footer + progress
// =============================================================================

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
    required this.bottomPadding,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
    decoration: const BoxDecoration(
      color: KolabingColors.surface,
      border: Border(top: BorderSide(color: KolabingColors.border)),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled && !loading ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: KolabingColors.primary,
          foregroundColor: KolabingColors.onPrimary,
          disabledBackgroundColor: KolabingColors.primary.withValues(
            alpha: 0.4,
          ),
          disabledForegroundColor: KolabingColors.onPrimary.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    KolabingColors.onPrimary,
                  ),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
      ),
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.stepIndex, required this.total});

  final int stepIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = (stepIndex + 1) / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          backgroundColor: KolabingColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(
            KolabingColors.primary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Step bodies
// =============================================================================

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.rubik(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: KolabingColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

class _StarRatingStep extends StatelessWidget {
  const _StarRatingStep({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => _StepFrame(
    title: 'How would you rate the Kolab?',
    subtitle: 'Tap a star — 1 means underwhelming, 5 means outstanding.',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final star = index + 1;
        final filled = value != null && star <= value!;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(star);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? LucideIcons.star : LucideIcons.star,
              size: 44,
              color: filled ? KolabingColors.primary : KolabingColors.border,
            ),
          ),
        );
      }),
    ),
  );
}

class _BucketStep extends StatelessWidget {
  const _BucketStep({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final OutputBucket? value;
  final ValueChanged<OutputBucket?> onChanged;

  @override
  Widget build(BuildContext context) => _StepFrame(
    title: title,
    subtitle: subtitle,
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: OutputBucket.values.map((bucket) {
        final selected = bucket == value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(selected ? null : bucket);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? KolabingColors.primary
                  : KolabingColors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? KolabingColors.primary
                    : KolabingColors.border,
              ),
            ),
            child: Text(
              bucket.label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? KolabingColors.onPrimary
                    : KolabingColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _RevenueStep extends StatefulWidget {
  const _RevenueStep({
    required this.amountCents,
    required this.skipped,
    required this.onChanged,
  });

  final int? amountCents;
  final bool skipped;
  final void Function(int? amount, {required bool skipped}) onChanged;

  @override
  State<_RevenueStep> createState() => _RevenueStepState();
}

class _RevenueStepState extends State<_RevenueStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.amountCents != null
          ? (widget.amountCents! / 100).toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAmountChange(String raw) {
    final cleaned = raw.replaceAll(RegExp('[^0-9]'), '');
    if (cleaned.isEmpty) {
      widget.onChanged(null, skipped: false);
      return;
    }
    final euros = int.tryParse(cleaned);
    if (euros == null) return;
    widget.onChanged(euros * 100, skipped: false);
  }

  @override
  Widget build(BuildContext context) => _StepFrame(
    title: 'Roughly how much revenue did this drive?',
    subtitle: "Best-guess EUR amount. You can skip if you'd rather not say.",
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !widget.skipped,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.openSans(
            fontSize: 16,
            color: KolabingColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '€ ',
            prefixStyle: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textPrimary,
            ),
            hintText: '0',
            hintStyle: GoogleFonts.openSans(
              fontSize: 16,
              color: KolabingColors.textTertiary,
            ),
            filled: true,
            fillColor: KolabingColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: KolabingColors.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: _handleAmountChange,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: widget.skipped,
              activeColor: KolabingColors.primary,
              checkColor: KolabingColors.onPrimary,
              onChanged: (checked) {
                if (checked ?? false) {
                  _controller.clear();
                  widget.onChanged(null, skipped: true);
                } else {
                  widget.onChanged(null, skipped: false);
                }
              },
            ),
            Expanded(
              child: Text(
                "I'd rather not say",
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ExpectationsStep extends StatefulWidget {
  const _ExpectationsStep({
    required this.rating,
    required this.comment,
    required this.onChanged,
  });

  final int? rating;
  final String? comment;
  final void Function(int? rating, String? comment) onChanged;

  @override
  State<_ExpectationsStep> createState() => _ExpectationsStepState();
}

class _ExpectationsStepState extends State<_ExpectationsStep> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _StepFrame(
    title: 'Did it match your expectations?',
    subtitle:
        'Optional — a quick rating plus anything else you want the community to know.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final selected = widget.rating == rating;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onChanged(
                  selected ? null : rating,
                  _commentController.text.isEmpty
                      ? null
                      : _commentController.text,
                );
              },
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? KolabingColors.primary
                      : KolabingColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? KolabingColors.primary
                        : KolabingColors.border,
                  ),
                ),
                child: Text(
                  '$rating',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? KolabingColors.onPrimary
                        : KolabingColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          maxLines: 4,
          maxLength: 400,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Anything else worth sharing? (optional)',
            hintStyle: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textTertiary,
            ),
            filled: true,
            fillColor: KolabingColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KolabingColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: KolabingColors.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: (value) => widget.onChanged(
            widget.rating,
            value.trim().isEmpty ? null : value,
          ),
        ),
      ],
    ),
  );
}

/// Community-only: multiselect of the benefits the community received (free
/// venue, discounts, freebies, professional content, or a custom "Other").
/// Required — at least one benefit must be picked to finish.
class _BenefitsStep extends StatefulWidget {
  const _BenefitsStep({
    required this.selected,
    required this.otherText,
    required this.onChanged,
  });

  final Set<BenefitType> selected;
  final String? otherText;
  final void Function(Set<BenefitType> selected, String? otherText) onChanged;

  @override
  State<_BenefitsStep> createState() => _BenefitsStepState();
}

class _BenefitsStepState extends State<_BenefitsStep> {
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(text: widget.otherText ?? '');
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _toggle(BenefitType benefit) {
    HapticFeedback.selectionClick();
    final next = Set<BenefitType>.from(widget.selected);
    if (next.contains(benefit)) {
      next.remove(benefit);
    } else {
      next.add(benefit);
    }
    final otherText = next.contains(BenefitType.other)
        ? (_otherController.text.trim().isEmpty
              ? null
              : _otherController.text.trim())
        : null;
    widget.onChanged(next, otherText);
  }

  @override
  Widget build(BuildContext context) {
    final showOther = widget.selected.contains(BenefitType.other);
    return _StepFrame(
      title: 'What benefits did you receive?',
      subtitle: 'Select all that apply — what the business provided to you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BenefitType.values.map((benefit) {
              final selected = widget.selected.contains(benefit);
              return GestureDetector(
                onTap: () => _toggle(benefit),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? KolabingColors.primary
                        : KolabingColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? KolabingColors.primary
                          : KolabingColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? LucideIcons.check : LucideIcons.plus,
                        size: 15,
                        color: selected
                            ? KolabingColors.onPrimary
                            : KolabingColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        benefit.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? KolabingColors.onPrimary
                              : KolabingColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (showOther) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otherController,
              maxLength: 120,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Describe the other benefit',
                hintStyle: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textTertiary,
                ),
                filled: true,
                fillColor: KolabingColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KolabingColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KolabingColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: KolabingColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) => widget.onChanged(
                widget.selected,
                value.trim().isEmpty ? null : value.trim(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendStep extends StatelessWidget {
  const _RecommendStep({
    required this.variant,
    required this.value,
    required this.onChanged,
  });

  final FeedbackVariant variant;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _StepFrame(
    title: variant.isBusiness
        ? 'Would you recommend this community?'
        : 'Would you recommend this business?',
    subtitle: variant.isBusiness
        ? 'Other businesses will see this signal — be honest, it helps everyone.'
        : 'Other communities will see this signal — be honest, it helps everyone.',
    child: Row(
      children: [
        Expanded(
          child: _RecommendTile(
            label: 'Yes',
            icon: LucideIcons.thumbsUp,
            selected: value ?? false,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(true);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RecommendTile(
            label: 'No',
            icon: LucideIcons.thumbsDown,
            selected: value == false,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(false);
            },
          ),
        ),
      ],
    ),
  );
}

class _RecommendTile extends StatelessWidget {
  const _RecommendTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: selected
            ? KolabingColors.primary
            : KolabingColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? KolabingColors.primary : KolabingColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: selected
                ? KolabingColors.onPrimary
                : KolabingColors.textPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: selected
                  ? KolabingColors.onPrimary
                  : KolabingColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.draft});

  final CollaborationFeedbackDraft draft;

  String _bucketLabel(OutputBucket? bucket) => bucket?.label ?? '—';

  String _revenueLabel() {
    if (draft.revenueSkipped) return 'Prefer not to say';
    if (draft.revenueAmountCents == null) return '—';
    return '€${(draft.revenueAmountCents! / 100).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) => _StepFrame(
    title: 'Review your answers',
    subtitle: 'Anything off? Tap back to edit. Otherwise hit submit below.',
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        children: [
          _ReviewRow(
            label: 'Star rating',
            value: '${draft.starRating ?? 0} / 5',
          ),
          // Business-only rows
          if (draft.variant.isBusiness) ...[
            _ReviewRow(
              label: 'Stories posted',
              value: _bucketLabel(draft.storiesPosted),
            ),
          ],
          // Community-only rows
          if (draft.variant.isCommunity && draft.benefits.isNotEmpty)
            _ReviewRow(label: 'Benefits', value: draft.benefitsAsText),
          _ReviewRow(
            label: 'Posts / reels',
            value: _bucketLabel(draft.postsReels),
          ),
          if (draft.variant.isBusiness)
            _ReviewRow(label: 'Revenue', value: _revenueLabel()),
          _ReviewRow(
            label: 'Met expectations',
            value: draft.metExpectationsRating != null
                ? '${draft.metExpectationsRating} / 5'
                : '—',
          ),
          if (draft.metExpectationsComment?.trim().isNotEmpty ?? false)
            _ReviewRow(
              label: 'Comment',
              value: draft.metExpectationsComment!.trim(),
            ),
          _ReviewRow(
            label: 'Recommend',
            value: draft.wouldRecommend == null
                ? '—'
                : (draft.wouldRecommend! ? 'Yes' : 'No'),
            isLast: true,
          ),
        ],
      ),
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ThankYouState extends StatelessWidget {
  const _ThankYouState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: KolabingColors.softYellow,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.heart,
            size: 36,
            color: KolabingColors.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Thanks for the feedback!',
          style: GoogleFonts.rubik(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'It helps other businesses find the right communities.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
