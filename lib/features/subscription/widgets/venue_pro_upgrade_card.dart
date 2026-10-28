import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../business/models/subscription.dart';

/// Whether to offer the Venue Pro upgrade: an active, App Store billed, non-Pro
/// subscription on a hotel, on iOS, once the store has the product. A Stripe
/// (web) subscriber is not offered it here: the app never links out to the web
/// checkout (Apple 3.1.1).
bool shouldOfferVenueProUpgrade({
  required bool isIos,
  required bool isActive,
  required Subscription? subscription,
  required bool hasProProduct,
  required bool isHotel,
}) =>
    isIos &&
    isActive &&
    hasProProduct &&
    isHotel &&
    subscription != null &&
    subscription.isAppleIAP &&
    !subscription.isPro;

/// Offered on the subscription screen to a hotel that already pays for a
/// standard plan through the App Store: move up to Venue Pro (ROLES §2.19).
/// Apple prorates the upgrade and keeps it on the same subscription.
class VenueProUpgradeCard extends StatelessWidget {
  const VenueProUpgradeCard({
    required this.price,
    required this.onUpgrade,
    this.isLoading = false,
    super.key,
  });

  /// The store's price, already rendered in euro.
  final String price;
  final VoidCallback? onUpgrade;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.softYellow,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: KolabingColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.hotel, size: 20),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  l10n.venueProUpgradeTitle(price),
                  style: KolabingTextStyles.titleMedium.copyWith(
                    color: KolabingColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.venueProUpgradeBody,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          KolabingButton(
            label: l10n.venueProUpgradeButton,
            onPressed: isLoading ? null : onUpgrade,
            variant: KolabingButtonVariant.primary,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}
