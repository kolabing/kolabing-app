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
import '../../auth/models/user_model.dart';
import '../../business/providers/profile_provider.dart';
import '../providers/wallet_provider.dart';

/// Referral program screen showing the referral code, instructions, and tiers.
///
/// Route: /community/referrals, /business/referrals
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key, this.userType});

  /// Optional override for the user type. If null, reads from profileProvider.
  final UserType? userType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);
    final code = state.referralCode ?? '---';

    final resolvedUserType =
        userType ?? ref.watch(profileProvider).profile?.userType;
    final isBusiness = resolvedUserType == UserType.business;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context).referralScreenTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface, letterSpacing: 1.0),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          children: [
            // Large referral code display
            _buildCodeDisplay(context, code),

            const SizedBox(height: KolabingSpacing.md),

            // Copy + Share buttons
            _buildActionButtons(context, code, ref),

            const SizedBox(height: KolabingSpacing.xl),

            // How it works
            _buildHowItWorks(context, isBusiness),

            const SizedBox(height: KolabingSpacing.lg),

            // Tier table
            _buildTierTable(context, isBusiness),

            const SizedBox(height: KolabingSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Code display
  // ---------------------------------------------------------------------------

  Widget _buildCodeDisplay(BuildContext context, String code) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      vertical: KolabingSpacing.xl,
      horizontal: KolabingSpacing.lg,
    ),
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: KolabingRadius.borderRadiusLg,
      boxShadow: [
        BoxShadow(
          color: context.colors.primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          AppLocalizations.of(context).referralScreenYourCode,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.onPrimary.withValues(alpha: 0.7), letterSpacing: 1.2),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Text(
          code,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: context.colors.onPrimary, letterSpacing: 3.0),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Action buttons
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(
    BuildContext context,
    String code,
    WidgetRef ref,
  ) => Row(
    children: [
      // Copy button
      Expanded(
        child: SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context).referralCodeCopied,
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: context.colors.success,
                ),
              );
            },
            icon: const Icon(LucideIcons.copy, size: 18),
            label: Text(
              AppLocalizations.of(context).referralScreenCopyCode,
              style: KolabingTextStyles.buttonSmall,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.onSurface,
              side: BorderSide(color: context.colors.darkBorder),
              shape: RoundedRectangleBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
            ),
          ),
        ),
      ),

      const SizedBox(width: KolabingSpacing.sm),

      // Share button
      Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Share.share(
                AppLocalizations.of(context).referralShareMessage(code),
              );
            },
            icon: const Icon(LucideIcons.share2, size: 18),
            label: Text(
              AppLocalizations.of(context).referralScreenShareCode,
              style: KolabingTextStyles.buttonSmall,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // How it works
  // ---------------------------------------------------------------------------

  Widget _buildHowItWorks(BuildContext context, bool isBusiness) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.referralScreenHowItWorks,
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          _buildStep(
            number: 1,
            title: l10n.referralScreenStep1Title,
            description: l10n.referralScreenStep1Desc,
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildStep(
            number: 2,
            title: l10n.referralScreenStep2Title,
            description: l10n.referralScreenStep2Desc,
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildStep(
            number: 3,
            title: isBusiness
                ? l10n.referralScreenStep3TitleBusiness
                : l10n.referralScreenStep3TitleCommunity,
            description: isBusiness
                ? l10n.referralScreenStep3DescBusiness
                : l10n.referralScreenStep3DescCommunity,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.colors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$number',
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onPrimary),
          ),
        ),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: KolabingTextStyles.titleSmall.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Tier table
  // ---------------------------------------------------------------------------

  Widget _buildTierTable(BuildContext context, bool isBusiness) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.referralScreenRewardTiers,
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.md),

          if (isBusiness) ...[
            _buildTierRow(
              icon: LucideIcons.userPlus,
              condition: l10n.referralScreenTierBusinessCondition,
              reward: l10n.referralScreenTierBusinessReward,
            ),
          ] else ...[
            _buildTierRow(
              icon: LucideIcons.userPlus,
              condition: l10n.referralScreenTier1MonthCondition,
              reward: l10n.referralScreenTier1MonthReward,
            ),
            const Divider(height: KolabingSpacing.lg),
            _buildTierRow(
              icon: LucideIcons.userPlus,
              condition: l10n.referralScreenTier4MonthCondition,
              reward: l10n.referralScreenTier4MonthReward,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTierRow({
    required IconData icon,
    required String condition,
    required String reward,
  }) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: context.colors.primary),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: Text(
          condition,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: context.colors.activeBg,
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Text(
          reward,
          style: KolabingTextStyles.labelSmall.copyWith(
            color: context.colors.activeText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
