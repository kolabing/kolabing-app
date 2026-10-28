import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscription/providers/iap_provider.dart';
import '../../subscription/services/iap_service.dart';

/// Shown on business onboarding the moment "hotel" is picked: what the hotel
/// plan costs, before the venue is asked to subscribe (SERR-201, Lab22).
///
/// iOS only. The plan is bought through the App Store (Apple 3.1.1), so on
/// Android, where the paywall does not offer it, this note would promise a plan
/// the venue cannot buy. The price is the store's when it has answered, else the
/// fixed €299.
class HotelPlanNote extends ConsumerWidget {
  const HotelPlanNote({super.key, @visibleForTesting this.isIosOverride});

  /// Tests run on a non-iOS host.
  final bool? isIosOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(isIosOverride ?? Platform.isIOS)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final price =
        ref.watch(iapProvider).displayPriceFor(SubscriptionPlan.venuePro) ??
        IAPState.kFallbackVenueProPrice;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.softYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.hotel, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hotelPlanNoteTitle(price),
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.hotelPlanNoteBody,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
