import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
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
/// Flow:
///   Step 0 — "Did the Kolab happen?" confirmation
///   Step 1 — Celebration + XP preview
///   Step 2 — Optional bonus actions (rating, review, photos, social)
///   Step 3 — Done with confetti summary
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
    _celebrationController.dispose();
    _xpCountController.dispose();
    super.dispose();
  }

  Future<void> _onConfirmComplete() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final collab = await completeCollaboration(widget.collaborationId);
      _updatedCollaboration = collab;
      setState(() {
        _step = 1;
        _isLoading = false;
      });
      _celebrationController.forward();
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  void _goToDone() => setState(() => _step = 2);

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KolabingColors.border,
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
        return _StepCelebration(
          key: const ValueKey(1),
          scaleAnimation: _scaleAnimation,
          fadeAnimation: _fadeAnimation,
          baseXp: _baseXp,
          onContinue: _goToDone,
        );
      case 2:
        return _StepDone(
          key: const ValueKey(2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Did the Kolab happen? 🎯',
          style: GoogleFonts.rubik(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mark your Kolab with $partnerName as complete.',
          style: GoogleFonts.openSans(
            fontSize: 15,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              error!,
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.error,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _PrimaryButton(
          label: isLoading ? 'Completing…' : 'Yes, complete Kolab ✨',
          isLoading: isLoading,
          onTap: isLoading ? null : onConfirm,
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: 'Not yet',
          onTap: onDismiss,
        ),
      ],
    );
  }
}

// =============================================================================
// Step 1 — Celebration
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
                'Kolab completed! 🎉',
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You earned XP and your profile now reflects this completed Kolab.',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
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
          label: 'See my XP →',
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
      decoration: BoxDecoration(
        color: KolabingColors.primary,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        '+$baseXp XP earned ⚡',
        style: GoogleFonts.rubik(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: KolabingColors.textPrimary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        const Text('🏆', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 24),
        Text(
          'All done! 🏆',
          style: GoogleFonts.rubik(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This Kolab is complete. Check your profile to see your growing history of collaborations.',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
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
                KolabingColors.primary,
                KolabingColors.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '+$totalXp XP',
                style: GoogleFonts.rubik(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: KolabingColors.textPrimary,
                ),
              ),
              Text(
                'XP earned',
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  color: KolabingColors.textPrimary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(label: 'Close', onTap: onClose),
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
        decoration: BoxDecoration(
          color: onTap != null ? KolabingColors.primary : KolabingColors.border,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
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
        child: Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 15,
            color: KolabingColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

