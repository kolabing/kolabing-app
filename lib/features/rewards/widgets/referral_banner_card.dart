import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../providers/wallet_provider.dart';
import '../utils/referral_share.dart';

/// A banner card prompting the user to reveal and share their referral code.
///
/// Reads the [referralCode] from [walletProvider] and opens a bottom sheet
/// where the user can copy or share the code.
class ReferralBannerCard extends ConsumerWidget {
  const ReferralBannerCard({super.key});

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: KolabingRadius.borderRadiusLg,
      ),
      child: Row(
        children: [
          // Left content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EARN BY SHARING',
                  style: KolabingTextStyles.labelSmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.0),
                ),
                const SizedBox(height: KolabingSpacing.xxs),
                Text(
                  'Refer 3 businesses \u2192 earn \u20AC75 cash',
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                OutlinedButton(
                  onPressed: () =>
                      _showReferralCodeSheet(context, referralCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KolabingColors.onSurface,
                    side: const BorderSide(color: KolabingColors.onSurface),
                    shape: RoundedRectangleBorder(
                      borderRadius: KolabingRadius.borderRadiusSm,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.md,
                      vertical: KolabingSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'SHARE REFERRAL CODE',
                    style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.md),
          // Right icon
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: KolabingColors.softYellow,
            ),
            child: const Icon(
              LucideIcons.gift,
              size: 28,
              color: KolabingColors.onSurface,
            ),
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
    decoration: const BoxDecoration(
      color: KolabingColors.surface,
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
              color: KolabingColors.darkBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Text(
            'YOUR REFERRAL CODE',
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: KolabingColors.textTertiary, letterSpacing: 1.2),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.softYellow,
              borderRadius: KolabingRadius.borderRadiusLg,
              border: Border.all(color: KolabingColors.softYellowBorder),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: KolabingColors.onSurface, letterSpacing: 2.5),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            'Ask businesses to use this code during signup.',
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _copyCode(context),
              icon: const Icon(LucideIcons.copy, size: 18),
              label: Text('COPY CODE', style: KolabingTextStyles.buttonSmall),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.onSurface,
                side: const BorderSide(color: KolabingColors.darkBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _shareCode(context),
              icon: const Icon(LucideIcons.share2, size: 18),
              label: Text(
                'SHARE CODE',
                style: KolabingTextStyles.buttonSmall.copyWith(
                  color: KolabingColors.onPrimary,
                ),
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
        ],
      ),
    ),
  );

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied'),
        backgroundColor: KolabingColors.success,
      ),
    );
  }

  Future<void> _shareCode(BuildContext context) async {
    final message = buildReferralCodeShareMessage(code);

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
            const SnackBar(
              content: Text('Sharing is unavailable. Referral code copied.'),
              backgroundColor: KolabingColors.onSurface,
            ),
          );
        }
      }
    } on Exception {
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open share sheet. Referral code copied.'),
            backgroundColor: KolabingColors.onSurface,
          ),
        );
      }
    }
  }
}
