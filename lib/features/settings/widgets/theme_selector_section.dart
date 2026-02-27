import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../providers/theme_provider.dart';

/// Theme selector section for profile screens
class ThemeSelectorSection extends ConsumerWidget {
  const ThemeSelectorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
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
                color: KolabingColors.primary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'Appearance',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Theme options
          _ThemeOption(
            icon: LucideIcons.smartphone,
            label: 'System',
            description: 'Follow device settings',
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
            label: 'Light',
            description: 'Always use light theme',
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
            label: 'Dark',
            description: 'Always use dark theme',
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
            ? KolabingColors.primary.withValues(alpha: 0.15)
            : KolabingColors.softYellow)
        : (isDark ? KolabingColors.darkBackground : KolabingColors.surfaceVariant);

    final borderColor = isSelected
        ? KolabingColors.primary
        : (isDark ? KolabingColors.darkBorder : KolabingColors.border);

    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;

    final subtitleColor =
        isDark ? KolabingColors.textTertiary : KolabingColors.textSecondary;

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
                    ? KolabingColors.primary
                    : (isDark
                        ? KolabingColors.darkSurface
                        : KolabingColors.surface),
                borderRadius: KolabingRadius.borderRadiusSm,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? KolabingColors.onPrimary
                    : (isDark
                        ? KolabingColors.textOnDark
                        : KolabingColors.textSecondary),
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
                decoration: const BoxDecoration(
                  color: KolabingColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 14,
                  color: KolabingColors.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
