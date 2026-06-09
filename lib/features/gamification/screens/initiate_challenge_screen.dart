import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
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

    final completion = await ref
        .read(initiateChallengeProvider.notifier)
        .initiate(
          challengeId: widget.challengeId,
          eventId: widget.eventId,
          verifierProfileId: verifierProfileId,
        );

    if (!mounted) return;

    if (completion != null) {
      _showSuccessDialog();
    } else {
      final error = ref.read(initiateChallengeProvider).error;
      _showErrorSnackBar(
        error ?? AppLocalizations.of(context).initiateChallengeFailed,
      );
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
                  color: context.colors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.check,
                  size: 40,
                  color: context.colors.success,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              Text(
                AppLocalizations.of(context).initiateChallengeSuccessTitle,
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).initiateChallengeSuccessBody,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
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
                    backgroundColor: context.colors.success,
                    foregroundColor: KolabingColors.textOnDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    AppLocalizations.of(context).commonDone,
                    style: KolabingTextStyles.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initiateState = ref.watch(initiateChallengeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? context.colors.surface
        : context.colors.background;
    final textColor = isDark
        ? context.colors.textOnDark
        : context.colors.onSurface;
    final surfaceColor = isDark
        ? context.colors.darkSurface
        : context.colors.surface;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.initiateChallengeTitle,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
      body: KeyboardAvoidingContent(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                            ? context.colors.darkBorder
                            : context.colors.darkBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.target,
                            size: 24,
                            color: context.colors.primary,
                          ),
                        ),
                        const SizedBox(width: KolabingSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.challenge!.name,
                                style: KolabingTextStyles.bodyMedium.copyWith(
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
                                      color: context.colors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.initiateChallengePointsAwarded(widget.challenge!.points),
                                      style: KolabingTextStyles.bodySmall.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: context.colors.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.challenge!.difficulty.label,
                                    style: KolabingTextStyles.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: context.colors.onSurfaceVariant,
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
                  l10n.initiateChallengeHowItWorks,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                _InstructionStep(
                  number: '1',
                  text: l10n.initiateChallengeStep1,
                ),
                _InstructionStep(
                  number: '2',
                  text: l10n.initiateChallengeStep2,
                ),
                _InstructionStep(
                  number: '3',
                  text: l10n.initiateChallengeStep3,
                ),
                _InstructionStep(number: '4', text: l10n.initiateChallengeStep4),

                const SizedBox(height: KolabingSpacing.xl),

                // Verifier ID input
                Text(
                  l10n.initiateChallengeVerifierLabel,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                TextFormField(
                  controller: _verifierIdController,
                  enabled: !initiateState.isLoading,
                  decoration: InputDecoration(
                    hintText: l10n.initiateChallengeVerifierHint,
                    hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                      color: context.colors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.user,
                      color: context.colors.textTertiary,
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? context.colors.darkBorder
                            : context.colors.darkBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? context.colors.darkBorder
                            : context.colors.darkBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.error),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.initiateChallengeVerifierRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  l10n.initiateChallengeVerifierHelper,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: context.colors.textTertiary,
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
                      disabledBackgroundColor: context.colors.primary
                          .withValues(alpha: 0.5),
                    ),
                    child: initiateState.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            l10n.initiateChallengeSubmit,
                            style: KolabingTextStyles.button.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.text});

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
              color: context.colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
