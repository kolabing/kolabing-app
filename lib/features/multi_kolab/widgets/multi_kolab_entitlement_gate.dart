import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';

/// Shown to a profile that does not hold the Event Creator entitlement.
///
/// The Event Creator capability is **independent of the Business
/// subscription** — a Community can hold it, and a subscribed Business can
/// lack it. Nothing in this feature may consult `hasActiveSubscription()`.
/// The backend remains the authority: this widget only avoids showing
/// create/publish affordances that would be refused with
/// `403 event_creator_required`.
class MultiKolabEntitlementGate extends StatelessWidget {
  const MultiKolabEntitlementGate({super.key, this.onRequestAccess});

  /// Entry point to the upgrade / request-access flow. When null the CTA is
  /// hidden rather than rendered dead.
  final VoidCallback? onRequestAccess;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          key: const Key('multiKolabEntitlementGate'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: colors.primaryTint,
                borderRadius: KolabingRadius.borderRadiusRound,
              ),
              child: Icon(LucideIcons.sparkles, color: colors.ink, size: 28),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.multiKolabEntitlementGateTitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.sectionHeader.copyWith(
                color: colors.ink,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.multiKolabEntitlementGateBody,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: colors.inkBody,
              ),
            ),
            if (onRequestAccess != null) ...[
              const SizedBox(height: KolabingSpacing.lg),
              KolabingButton(
                key: const Key('multiKolabEntitlementGateCta'),
                label: l10n.multiKolabEntitlementGateCta,
                onPressed: onRequestAccess,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
