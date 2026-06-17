import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';
import '../l10n/app_localizations.dart';

/// Centered "Coming soon" placeholder.
///
/// Reused everywhere a member/attendee surface is still reachable while the
/// attendee layer is gated off (see [FeatureFlags.attendeeEnabled]). Shows a
/// soft icon badge, a "Coming soon" headline and one supporting line, all from
/// design tokens. Pass [title]/[message]/[icon] to customise; otherwise the
/// localized defaults are used.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    super.key,
    this.title,
    this.message,
    this.icon,
  });

  /// Headline. Defaults to the localized "Coming soon".
  final String? title;

  /// One-line supporting copy. Defaults to the localized member-layer message.
  final String? message;

  /// Leading icon. Defaults to a sparkles glyph.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.colors.softYellow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? LucideIcons.sparkles,
                  size: 32,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                title ?? l10n.comingSoonTitle,
                style: KolabingTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                message ?? l10n.comingSoonMessage,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
