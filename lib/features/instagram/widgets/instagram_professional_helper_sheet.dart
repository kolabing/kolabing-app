import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';

/// How to switch a personal Instagram account to a professional one.
///
/// Instagram's API only serves Professional (Business / Creator) accounts, so
/// this is the one thing a personal-account owner has to do before Connect can
/// work. The steps follow Instagram's own menu names.
class InstagramProfessionalHelperSheet extends StatelessWidget {
  const InstagramProfessionalHelperSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (_) => const InstagramProfessionalHelperSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <String>[
      l10n.instagramPersonalStep1,
      l10n.instagramPersonalStep2,
      l10n.instagramPersonalStep3,
      l10n.instagramPersonalStep4,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.lg,
          0,
          KolabingSpacing.lg,
          KolabingSpacing.lg,
        ),
        child: Column(
          key: const Key('instagram-professional-helper'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.instagram,
                  size: 22,
                  color: context.colors.onSurface,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.instagramPersonalTitle,
                    style: KolabingTextStyles.titleLarge.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.instagramPersonalBody,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: KolabingRadius.borderRadiusRound,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: KolabingTextStyles.labelSmall.copyWith(
                          color: context.colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: KolabingSpacing.sm),
            KolabingButton(
              label: l10n.instagramPersonalGotIt,
              onPressed: () => Navigator.of(context).pop(),
              variant: KolabingButtonVariant.secondary,
              size: KolabingButtonSize.compact,
            ),
          ],
        ),
      ),
    );
  }
}
