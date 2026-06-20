import 'package:flutter/material.dart';
import 'package:kolabing_app/config/constants/radius.dart';
import 'package:kolabing_app/config/theme/color_tokens.dart';
import 'package:kolabing_app/config/theme/typography.dart';

class KolabingSelectableChip extends StatelessWidget {
  const KolabingSelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
