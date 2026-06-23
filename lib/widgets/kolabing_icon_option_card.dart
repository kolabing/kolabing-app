import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';

class KolabingIconOptionCard extends StatelessWidget {
  const KolabingIconOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? colors.primaryTint : colors.surface,
          border: Border.all(
            color: selected ? colors.ink : colors.hairline,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(KolabingRadius.optionCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(
                color: selected ? colors.ink : colors.inkBody,
                size: 28,
              ),
              child: icon,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: KolabingTextStyles.chipLabel.copyWith(
                color: selected ? colors.ink : colors.inkBody,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle_rounded, size: 16, color: colors.ink),
            ],
          ],
        ),
      ),
    );
  }
}
