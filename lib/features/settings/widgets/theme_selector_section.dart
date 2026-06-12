import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

/// Theme selector section for profile screens
class ThemeSelectorSection extends ConsumerWidget {
  const ThemeSelectorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(
                LucideIcons.palette,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                l10n.themeSelectorTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? context.colors.textOnDark
                      : context.colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Theme options
          _ThemeOption(
            icon: LucideIcons.smartphone,
            label: l10n.themeSelectorSystemLabel,
            description: l10n.themeSelectorSystemDescription,
            isSelected: themeState.themeMode == ThemeMode.system,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
            },
            isDark: isDark,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _ThemeOption(
            icon: LucideIcons.sun,
            label: l10n.themeSelectorLightLabel,
            description: l10n.themeSelectorLightDescription,
            isSelected: themeState.themeMode == ThemeMode.light,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
            },
            isDark: isDark,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _ThemeOption(
            icon: LucideIcons.moon,
            label: l10n.themeSelectorDarkLabel,
            description: l10n.themeSelectorDarkDescription,
            isSelected: themeState.themeMode == ThemeMode.dark,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? (isDark
            ? context.colors.primary.withValues(alpha: 0.15)
            : context.colors.softYellow)
        : (isDark ? context.colors.surface : context.colors.surfaceVariant);

    final borderColor = isSelected
        ? context.colors.primary
        : (isDark ? context.colors.darkBorder : context.colors.darkBorder);

    final textColor =
        isDark ? context.colors.textOnDark : context.colors.onSurface;

    final subtitleColor =
        isDark ? context.colors.textTertiary : context.colors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: KolabingRadius.borderRadiusMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.primary
                    : (isDark
                        ? context.colors.darkSurface
                        : context.colors.surface),
                borderRadius: KolabingRadius.borderRadiusSm,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? context.colors.onPrimary
                    : (isDark
                        ? context.colors.textOnDark
                        : context.colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),

            // Label and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: KolabingTextStyles.titleSmall.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.check,
                  size: 14,
                  color: context.colors.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
