import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../providers/wallet_provider.dart';

/// A banner card prompting the user to share their referral link.
///
/// Reads the [referralCode] from [walletProvider] and builds a share message
/// using `share_plus`. The card displays a gift icon, headline, description,
/// and a prominent share button.
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
        color: KolabingColors.surfaceVariant,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.softYellowBorder),
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
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: KolabingColors.textTertiary,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xxs),
                Text(
                  'Invite a business, earn up to \u20AC20',
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                OutlinedButton(
                  onPressed: () =>
                      _shareReferralLink(context, referralCode, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KolabingColors.textPrimary,
                    side: const BorderSide(color: KolabingColors.textPrimary),
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
                    'SHARE MY LINK',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
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
              color: KolabingColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Share
  // ---------------------------------------------------------------------------

  Future<void> _shareReferralLink(
    BuildContext context,
    String code,
    WidgetRef ref,
  ) async {
    final link =
        ref.read(walletProvider).referralLink ??
        'https://kolabing.com/ref/$code';
    final message =
        'Join Kolabing and start earning rewards! '
        'Use my referral code $code when you sign up.\n$link';

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
        await Clipboard.setData(ClipboardData(text: link));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sharing is unavailable. Referral link copied.'),
              backgroundColor: KolabingColors.textPrimary,
            ),
          );
        }
      }
    } on Exception {
      await Clipboard.setData(ClipboardData(text: link));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open share sheet. Referral link copied.'),
            backgroundColor: KolabingColors.textPrimary,
          ),
        );
      }
    }
  }
}
