import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../auth/models/user_model.dart';
import '../../business/providers/profile_provider.dart';
import '../providers/wallet_provider.dart';

/// Referral program screen showing the referral code, instructions, and tiers.
///
/// Route: /community/referrals, /business/referrals
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({
    super.key,
    this.userType,
  });

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
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'REFERRAL PROGRAM',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textPrimary,
          ),
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
            _buildHowItWorks(isBusiness),

            const SizedBox(height: KolabingSpacing.lg),

            // Tier table
            _buildTierTable(isBusiness),

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
        color: KolabingColors.primary,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: KolabingColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'YOUR REFERRAL CODE',
            style: GoogleFonts.rubik(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: KolabingColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            code,
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.0,
              color: KolabingColors.onPrimary,
            ),
          ),
        ],
      ),
    );

  // ---------------------------------------------------------------------------
  // Action buttons
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context, String code, WidgetRef ref) => Row(
      children: [
        // Copy button
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Referral code copied'),
                    duration: Duration(seconds: 2),
                    backgroundColor: KolabingColors.success,
                  ),
                );
              },
              icon: const Icon(LucideIcons.copy, size: 18),
              label: Text(
                'COPY',
                style: KolabingTextStyles.buttonSmall,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
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
                final link = ref.read(walletProvider).referralLink ?? 'https://kolabing.com/ref/$code';
                Share.share(
                  'Join Kolabing with my referral code: $code\n$link',
                );
              },
              icon: const Icon(LucideIcons.share2, size: 18),
              label: Text(
                'SHARE',
                style: KolabingTextStyles.buttonSmall,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
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

  Widget _buildHowItWorks(bool isBusiness) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
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
            'HOW IT WORKS',
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),

          _buildStep(
            number: 1,
            title: 'Share your unique code',
            description: 'Send your referral code to friends and colleagues.',
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildStep(
            number: 2,
            title: 'A business subscribes using your code',
            description:
                'When they sign up and choose a plan, they enter your code.',
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildStep(
            number: 3,
            title: isBusiness
                ? 'You earn 1 free month of subscription'
                : 'You earn 50-100 points (EUR 10-EUR 20)',
            description: isBusiness
                ? 'Your next billing cycle is automatically extended.'
                : 'Points are added to your wallet and can be withdrawn.',
          ),
        ],
      ),
    );

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
          decoration: const BoxDecoration(
            color: KolabingColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: KolabingColors.onPrimary,
              ),
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
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.textSecondary,
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

  Widget _buildTierTable(bool isBusiness) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
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
            'REWARD TIERS',
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          if (isBusiness) ...[
            _buildTierRow(
              icon: LucideIcons.userPlus,
              condition: 'Each successful referral',
              reward: '1 free month',
            ),
          ] else ...[
            _buildTierRow(
              icon: LucideIcons.userPlus,
              condition: 'Referred user stays 1 month',
              reward: '50 pts (EUR 10)',
            ),
            const Divider(height: KolabingSpacing.lg),
            _buildTierRow(
              icon: LucideIcons.userPlus,
              condition: 'Referred user stays 4 months',
              reward: '100 pts (EUR 20)',
            ),
          ],
        ],
      ),
    );

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
            color: KolabingColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: KolabingColors.primary,
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Text(
            condition,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.sm,
            vertical: KolabingSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: KolabingColors.activeBg,
            borderRadius: KolabingRadius.borderRadiusRound,
          ),
          child: Text(
            reward,
            style: KolabingTextStyles.labelSmall.copyWith(
              color: KolabingColors.activeText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
}
