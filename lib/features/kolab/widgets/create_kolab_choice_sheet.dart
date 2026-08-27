import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../multi_kolab/providers/multi_kolab_providers.dart';

/// The single creation entry point for My Kolabs.
///
/// Replaces the standalone Multi-Kolab promo banner: a Multi-Kolab Event is
/// still a Kolab, so it is created from the same "+" action as an ordinary
/// one instead of from a separate product area.
Future<void> showCreateKolabChoiceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateKolabChoiceSheet(),
    );

class CreateKolabChoiceSheet extends ConsumerWidget {
  const CreateKolabChoiceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    // Entitlement decides the DESTINATION, never visibility: the option is
    // always offered and a non-entitled profile lands on the existing Event
    // Creator gate (the organizer area's own gate), matching how the create
    // flow already shows-then-gates a non-subscribed business.
    final entitled =
        ref
            .watch(multiKolabEntitlementProvider)
            .value
            ?.hasEventCreatorEntitlement ??
        false;

    return SafeArea(
      child: Container(
        key: const Key('createKolabChoiceSheet'),
        margin: const EdgeInsets.all(KolabingSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: KolabingRadius.borderRadiusCard,
          border: Border.all(color: colors.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KolabingSpacing.md,
                KolabingSpacing.sm,
                KolabingSpacing.md,
                KolabingSpacing.xs,
              ),
              child: Text(
                l10n.createKolabChoiceTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: colors.ink,
                ),
              ),
            ),
            _ChoiceTile(
              itemKey: const Key('createKolabChoiceOrdinary'),
              icon: LucideIcons.briefcase,
              title: l10n.createKolabChoiceKolabTitle,
              subtitle: l10n.createKolabChoiceKolabSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                context.push(KolabingRoutes.kolabNew);
              },
            ),
            _ChoiceTile(
              itemKey: const Key('createKolabChoiceMultiKolab'),
              icon: LucideIcons.users,
              title: l10n.createKolabChoiceMultiKolabTitle,
              subtitle: l10n.createKolabChoiceMultiKolabSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                context.push(
                  entitled
                      ? KolabingRoutes.multiKolabOrganizerEventNew
                      : KolabingRoutes.multiKolabOrganizerEvents,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.itemKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key itemKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      key: itemKey,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusSm,
              ),
              child: Icon(icon, size: 18, color: colors.ink),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: colors.inkBody,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.muted),
          ],
        ),
      ),
    );
  }
}
