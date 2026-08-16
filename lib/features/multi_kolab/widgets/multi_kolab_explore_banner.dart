import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

/// Additive-only entry point into the Multi-Kolab Event Explore flow,
/// placed above the ordinary Explore feed. Never modifies the ordinary
/// Explore screen's own cards/list/deck — purely an extra row.
class MultiKolabExploreBanner extends StatelessWidget {
  const MultiKolabExploreBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
      child: Material(
        color: colors.primaryTint,
        borderRadius: KolabingRadius.borderRadiusLg,
        child: InkWell(
          borderRadius: KolabingRadius.borderRadiusLg,
          onTap: () => context.push(KolabingRoutes.multiKolabExplore),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.users, size: 18, color: colors.primary),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.multiKolabExploreEntryPointLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        l10n.multiKolabExploreEntryPointSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
