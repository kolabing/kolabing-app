import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';

/// Screen to initiate a peer-to-peer challenge
class InitiateChallengeScreen extends ConsumerStatefulWidget {
  const InitiateChallengeScreen({
    super.key,
    required this.eventId,
    required this.challengeId,
    this.challenge,
  });

  final String eventId;
  final String challengeId;
  final Challenge? challenge;

  @override
  ConsumerState<InitiateChallengeScreen> createState() =>
      _InitiateChallengeScreenState();
}

class _InitiateChallengeScreenState
    extends ConsumerState<InitiateChallengeScreen> {
  final _verifierIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _verifierIdController.dispose();
    super.dispose();
  }

  Future<void> _handleInitiate() async {
    if (!_formKey.currentState!.validate()) return;

    final verifierProfileId = _verifierIdController.text.trim();

    final completion = await ref.read(initiateChallengeProvider.notifier).initiate(
          challengeId: widget.challengeId,
          eventId: widget.eventId,
          verifierProfileId: verifierProfileId,
        );

    if (!mounted) return;

    if (completion != null) {
      _showSuccessDialog();
    } else {
      final error = ref.read(initiateChallengeProvider).error;
      _showErrorSnackBar(error ?? 'Failed to initiate challenge');
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: KolabingColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 40,
                  color: KolabingColors.success,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                'Challenge Started!',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'The verifier will be notified to confirm your challenge completion.',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KolabingColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initiateState = ref.watch(initiateChallengeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? KolabingColors.darkBackground : KolabingColors.background;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;
    final surfaceColor =
        isDark ? KolabingColors.darkSurface : KolabingColors.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: textColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Start Challenge',
          style: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge info card
              if (widget.challenge != null)
                Container(
                  padding: const EdgeInsets.all(KolabingSpacing.md),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? KolabingColors.darkBorder
                          : KolabingColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: KolabingColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.target,
                          size: 24,
                          color: KolabingColors.primary,
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.challenge!.name,
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KolabingColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${widget.challenge!.points} pts',
                                    style: GoogleFonts.rubik(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: KolabingColors.onPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.challenge!.difficulty.label,
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: KolabingColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: KolabingSpacing.xl),

              // Instructions
              Text(
                'How it works',
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              _InstructionStep(
                number: '1',
                text: 'Enter the verifier\'s profile ID',
              ),
              _InstructionStep(
                number: '2',
                text: 'Complete the challenge with the verifier present',
              ),
              _InstructionStep(
                number: '3',
                text: 'The verifier confirms your completion',
              ),
              _InstructionStep(
                number: '4',
                text: 'Earn your points!',
              ),

              const SizedBox(height: KolabingSpacing.xl),

              // Verifier ID input
              Text(
                'Verifier Profile ID',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              TextFormField(
                controller: _verifierIdController,
                enabled: !initiateState.isLoading,
                decoration: InputDecoration(
                  hintText: 'Enter the verifier\'s profile ID',
                  hintStyle: GoogleFonts.openSans(
                    color: KolabingColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.user,
                    color: KolabingColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? KolabingColors.darkBorder
                          : KolabingColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? KolabingColors.darkBorder
                          : KolabingColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: KolabingColors.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: KolabingColors.error,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the verifier\'s profile ID';
                  }
                  return null;
                },
              ),

              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'Ask another attendee for their profile ID to verify your challenge',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.textTertiary,
                ),
              ),

              const SizedBox(height: KolabingSpacing.xl),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: initiateState.isLoading ? null : _handleInitiate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: initiateState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              KolabingColors.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'START CHALLENGE',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: KolabingColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
