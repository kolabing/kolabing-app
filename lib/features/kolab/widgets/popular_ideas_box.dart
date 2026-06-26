import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// "Popular ideas" helper card shown near the product/venue details step --
/// concrete Kolab ideas a business can copy, so the flow feels guided rather
/// than a blank form.
class PopularIdeasBox extends StatelessWidget {
  const PopularIdeasBox({required this.ideas, super.key});

  final List<String> ideas;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.softYellow,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: context.colors.softYellowBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.lightbulb,
              size: 16,
              color: context.colors.primaryDark,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              'POPULAR IDEAS',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.primaryDark,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        ...ideas.map(
          (idea) => Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xxs),
            child: Text(
              '• $idea',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12.5,
                color: context.colors.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
