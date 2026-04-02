import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';

/// A generic multi-select chip group.
///
/// Displays a [Wrap] of animated chips that the user can toggle on and off.
/// When [maxSelect] is reached, unselected chips become visually dimmed and
/// non-interactive.
class MultiSelectChips<T> extends StatelessWidget {
  const MultiSelectChips({
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.onToggle,
    super.key,
    this.iconBuilder,
    this.maxSelect,
  });

  /// All available items to display as chips.
  final List<T> items;

  /// Currently selected items.
  final List<T> selected;

  /// Builds the display label for each item.
  final String Function(T) labelBuilder;

  /// Optionally builds an icon to show before the label.
  final IconData? Function(T)? iconBuilder;

  /// Called when a chip is tapped.
  final void Function(T) onToggle;

  /// Maximum number of items that can be selected at the same time.
  /// When `null`, there is no limit.
  final int? maxSelect;

  @override
  Widget build(BuildContext context) {
    final maxReached =
        maxSelect != null && selected.length >= maxSelect!;

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: items.map((item) {
        final isSelected = selected.contains(item);
        final isDimmed = maxReached && !isSelected;
        final icon = iconBuilder?.call(item);

        return GestureDetector(
          onTap: isDimmed ? null : () => onToggle(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? KolabingColors.primary
                  : KolabingColors.surface,
              borderRadius: KolabingRadius.borderRadiusSm,
              border: Border.all(
                color: isSelected
                    ? KolabingColors.primary
                    : KolabingColors.border,
              ),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isDimmed ? 0.4 : 1.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textPrimary,
                    ),
                    const SizedBox(width: KolabingSpacing.xxs),
                  ],
                  Text(
                    labelBuilder(item),
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? KolabingColors.onPrimary
                          : KolabingColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
