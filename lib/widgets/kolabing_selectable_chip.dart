import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';

class KolabingSelectableChip extends StatelessWidget {
  const KolabingSelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.leadingIcon,
    this.disabled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leadingIcon;

  /// When true, the chip ignores taps and renders at reduced opacity.
  /// Does not affect already-selected chips (callers must pass disabled: false
  /// for selected items so they can still be deselected).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.primaryTint : colors.surface,
            border: Border.all(
              color: selected ? colors.ink : colors.hairline,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(KolabingRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: KolabingTextStyles.chipLabel.copyWith(
                  color: selected ? colors.ink : colors.inkBody,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
