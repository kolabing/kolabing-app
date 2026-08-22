import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';

/// How a scan outcome reads: sets the icon and accent colour.
enum ScanOutcomeTone { success, info, failure }

/// The one sheet every scan outcome uses — check-in confirmed, already checked
/// in, challenge confirmed, rejected, or any failure.
///
/// A sheet rather than a dialog on purpose: `mobile_scanner` keeps running
/// behind it, so dismissing returns straight to a live camera instead of
/// tearing the scanner down and rebuilding it. It also keeps the scanner off
/// the modal-dialog path entirely.
class ScanOutcomeSheet extends StatelessWidget {
  const ScanOutcomeSheet({
    super.key,
    required this.tone,
    required this.title,
    this.body,
    this.xpEarned,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final ScanOutcomeTone tone;
  final String title;
  final String? body;

  /// Points the **server** awarded. Never a locally computed number — a wrong
  /// XP figure is worse than none (see BACKLOG FX-8).
  final int? xpEarned;

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Shows the sheet. Resolves when it closes.
  static Future<void> show(
    BuildContext context, {
    required ScanOutcomeTone tone,
    required String title,
    String? body,
    int? xpEarned,
    String? primaryLabel,
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanOutcomeSheet(
        tone: tone,
        title: title,
        body: body,
        xpEarned: xpEarned,
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
      ),
    );
  }

  IconData get _icon => switch (tone) {
    ScanOutcomeTone.success => LucideIcons.check,
    ScanOutcomeTone.info => LucideIcons.info,
    ScanOutcomeTone.failure => LucideIcons.x,
  };

  Color _accent(BuildContext context) => switch (tone) {
    ScanOutcomeTone.success => context.colors.success,
    ScanOutcomeTone.info => context.colors.primaryDark,
    ScanOutcomeTone.failure => context.colors.error,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = _accent(context);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 36, color: accent),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (xpEarned != null && xpEarned! > 0) ...[
            const SizedBox(height: KolabingSpacing.md),
            _XpPill(points: xpEarned!),
          ],
          const SizedBox(height: KolabingSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: KolabingButton(
              label: primaryLabel ?? l10n.commonGotIt,
              onPressed: onPrimary ?? () => Navigator.of(context).pop(),
              variant: KolabingButtonVariant.primary,
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSecondary ?? () => Navigator.of(context).pop(),
                child: Text(
                  secondaryLabel!,
                  style: KolabingTextStyles.button.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "+15 XP" pill, styled with the XP tokens so it reads the same everywhere.
class _XpPill extends StatelessWidget {
  const _XpPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.xpGreenContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.zap, size: 16, color: context.colors.xpGreen),
          const SizedBox(width: 6),
          Text(
            l10n.checkinXpEarned(points),
            style: KolabingTextStyles.labelLarge.copyWith(
              color: context.colors.xpGreenOnContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
