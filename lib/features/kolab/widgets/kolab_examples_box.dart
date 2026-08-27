import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// A small "Examples" card shown beneath a writing field to reduce
/// blank-page anxiety — short, concrete example phrasings a business could
/// use, not just a tooltip.
class KolabExamplesBox extends StatelessWidget {
  const KolabExamplesBox({
    required this.examples,
    super.key,
    this.label = 'EXAMPLES',
  });

  final String label;
  final List<String> examples;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.sm),
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant,
      borderRadius: KolabingRadius.borderRadiusSm,
      border: Border.all(color: context.colors.darkBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.colors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        ...examples.map(
          (example) => Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.sparkle,
                  size: 12,
                  color: context.colors.textTertiary,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    example,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: context.colors.onSurfaceVariant,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
