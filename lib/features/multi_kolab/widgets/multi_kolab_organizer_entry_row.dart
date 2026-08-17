import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';

/// Entry point into the Multi-Kolab organizer area, shown at the top of the
/// My Kolabs "Offers" tab for both account types.
///
/// Deliberately a row rather than a fifth segment in
/// `MyKolabsHubScreen`'s segmented control: that control is shared by every
/// user and already carries four segments, and Multi-Kolab is an
/// entitlement-gated capability most profiles do not hold.
class MultiKolabOrganizerEntryRow extends StatelessWidget {
  const MultiKolabOrganizerEntryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      child: InkWell(
        key: const Key('multiKolabOrganizerEntryRow'),
        borderRadius: KolabingRadius.borderRadiusCard,
        onTap: () => context.push(KolabingRoutes.multiKolabOrganizerEvents),
        child: Container(
          // Comfortably above the 48dp minimum tap target.
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: colors.softYellow,
            borderRadius: KolabingRadius.borderRadiusCard,
            border: Border.all(color: colors.softYellowBorder),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.users, size: 20, color: colors.ink),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.multiKolabOrganizerEntryTitle,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                    Text(
                      l10n.multiKolabOrganizerEntrySubtitle,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: colors.inkBody,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: colors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
