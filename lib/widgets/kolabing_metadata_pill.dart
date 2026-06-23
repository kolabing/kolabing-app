import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';

class KolabingMetadataPill extends StatelessWidget {
  const KolabingMetadataPill({
    required this.icon,
    required this.label,
    this.tintColor,
    super.key,
  });

  final Widget icon;
  final String label;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = tintColor ?? colors.surfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(KolabingRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: colors.inkBody, size: 12),
            child: icon,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: KolabingTextStyles.bodySm.copyWith(
              color: colors.inkBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
