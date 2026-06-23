import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/wallet_provider.dart';
import '../../../widgets/kolabing_button.dart';

/// A banner card prompting the user to reveal and share their referral code.
///
/// Reads the [referralCode] from [walletProvider] and opens a bottom sheet
/// where the user can copy or share the code.
///
/// When [usePastelStyle] is true, uses a pastel yellow background and border.
class ReferralBannerCard extends ConsumerWidget {
  const ReferralBannerCard({super.key, this.usePastelStyle = false});

  final bool usePastelStyle;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralCode = ref.watch(
      walletProvider.select((s) => s.referralCode),
    );

    // Don't render until we have a code.
    if (referralCode == null || referralCode.isEmpty) {
      return const SizedBox.shrink();
    }

    const inkColor = Color(0xFF19150F);
    const amberLabel = Color(0xFF9A7C28);
    const stepBoxFill = Color(0xFFFFF9E6);
    const badgeFill = Color(0xFFFFE28C);
    const arrowCircleFill = Color(0xFFFFFDF5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: KolabingColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + gift icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).referralBannerEarnBySharing,
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: amberLabel,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: arrowCircleFill,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KolabingColors.softYellowBorder,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  LucideIcons.gift,
                  size: 17,
                  color: inkColor,
                  semanticLabel: '',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2-step flow row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step 1 box
                Expanded(
                  child: _StepBox(
                    stepNumber: '1',
                    badgeFill: badgeFill,
                    fill: stepBoxFill,
                    inkColor: inkColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .referralBannerStepReferLabel,
                          style: KolabingTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: inkColor.withValues(alpha: 0.55),
                            height: 1.2,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                              .referralBannerStepReferValue,
                          style: KolabingTextStyles.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: inkColor,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Center arrow connector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: arrowCircleFill,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KolabingColors.hairline,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: inkColor,
                      ),
                    ),
                  ),
                ),

                // Step 2 box
                Expanded(
                  child: _StepBox(
                    stepNumber: '2',
                    badgeFill: badgeFill,
                    fill: stepBoxFill,
                    inkColor: inkColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .referralBannerStepEarnLabel,
                          style: KolabingTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: inkColor.withValues(alpha: 0.55),
                            height: 1.2,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                              .referralBannerStepEarnAmount,
                          style: KolabingTextStyles.displaySmall.copyWith(
                            fontSize: 32,
                            color: inkColor,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                              .referralBannerStepEarnSuffix,
                          style: KolabingTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: inkColor.withValues(alpha: 0.55),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CTA button
          KolabingButton(
            label: AppLocalizations.of(context).referralBannerShareButton,
            onPressed: () => _showReferralCodeSheet(context, referralCode),
            variant: KolabingButtonVariant.dark,
            icon: const Icon(LucideIcons.share2),
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sheet
  // ---------------------------------------------------------------------------

  Future<void> _showReferralCodeSheet(BuildContext context, String code) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) => _ReferralCodeSheet(code: code),
      );
}

// ---------------------------------------------------------------------------
// Step box widget — soft inset rounded box with numbered badge
// ---------------------------------------------------------------------------

class _StepBox extends StatelessWidget {
  const _StepBox({
    required this.stepNumber,
    required this.badgeFill,
    required this.fill,
    required this.inkColor,
    required this.child,
  });

  final String stepNumber;
  final Color badgeFill;
  final Color fill;
  final Color inkColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KolabingColors.softYellowBorder.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: child,
        ),
        // Step number badge — top-center
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: badgeFill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: KolabingColors.primary,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: TextStyle(
                    fontFamily: KolabingTypography.fontLabel,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: inkColor,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferralCodeSheet extends StatelessWidget {
  const _ReferralCodeSheet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.lg,
      KolabingSpacing.md,
      KolabingSpacing.lg,
      KolabingSpacing.lg,
    ),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.darkBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            AppLocalizations.of(context).referralSheetYourCode,
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textTertiary, letterSpacing: 1.2),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              borderRadius: KolabingRadius.borderRadiusLg,
              border: Border.all(color: context.colors.softYellowBorder),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: context.colors.onSurface, letterSpacing: 2.5),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            AppLocalizations.of(context).referralSheetInstructions,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          KolabingButton(
            label: AppLocalizations.of(context).referralSheetCopyCode,
            onPressed: () => _copyCode(context),
            variant: KolabingButtonVariant.secondary,
            icon: const Icon(LucideIcons.copy),
            height: 48,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          KolabingButton(
            label: AppLocalizations.of(context).referralSheetShareCode,
            onPressed: () => _shareCode(context),
            variant: KolabingButtonVariant.primary,
            icon: const Icon(LucideIcons.share2),
            height: 48,
          ),
        ],
      ),
    ),
  );

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).referralCodeCopied),
        backgroundColor: context.colors.success,
      ),
    );
  }

  Future<void> _shareCode(BuildContext context) async {
    final message = AppLocalizations.of(context).referralShareMessage(code);

    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    try {
      final result = await Share.share(
        message,
        sharePositionOrigin: shareOrigin,
      );

      if (result.status == ShareResultStatus.unavailable && context.mounted) {
        await Clipboard.setData(ClipboardData(text: code));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).referralSheetShareUnavailable,
              ),
              backgroundColor: context.colors.onSurface,
            ),
          );
        }
      }
    } on Exception {
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).referralSheetShareFailed,
            ),
            backgroundColor: context.colors.onSurface,
          ),
        );
      }
    }
  }
}
