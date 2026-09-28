import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';

/// Centered spinner for the league / level screens.
class LeagueLoadingView extends StatelessWidget {
  const LeagueLoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Centered message (unavailable / error with retry) for league screens.
class LeagueMessageView extends StatelessWidget {
  const LeagueMessageView({required this.text, this.onRetry, super.key});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            onRetry == null ? LucideIcons.trophy : LucideIcons.alertCircle,
            size: 40,
            color: context.colors.textTertiary,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            text,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: KolabingSpacing.lg),
            KolabingButton(
              label: AppLocalizations.of(context).commonRetry,
              onPressed: onRetry,
              variant: KolabingButtonVariant.primary,
              icon: const Icon(LucideIcons.refreshCw),
            ),
          ],
        ],
      ),
    ),
  );
}
