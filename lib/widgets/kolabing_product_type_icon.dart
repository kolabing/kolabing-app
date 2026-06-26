import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/theme/color_tokens.dart';
import '../features/kolab/enums/product_type.dart';

/// Icon for a [ProductType].
///
/// Uses the same Lucide icon set as the rest of the app instead of hand-drawn
/// paths, so it renders crisply and consistently at small sizes.
/// Stroke is the theme ink color (#19150F in light) unless [color] is given.
/// Any unmapped [ProductType] falls back to the "Other" glyph — it never
/// renders blank.
class KolabingProductTypeIcon extends StatelessWidget {
  const KolabingProductTypeIcon(
    this.type, {
    super.key,
    this.size = 18,
    this.color,
  });

  final ProductType type;
  final double size;
  final Color? color;

  static const Map<ProductType, IconData> _icons = {
    ProductType.foodProduct: LucideIcons.utensilsCrossed,
    ProductType.beverage: LucideIcons.cupSoda,
    ProductType.healthBeauty: LucideIcons.heart,
    ProductType.sportsEquipment: LucideIcons.dumbbell,
    ProductType.fashion: LucideIcons.shirt,
    ProductType.techGadget: LucideIcons.smartphone,
    ProductType.experienceService: LucideIcons.sparkles,
    ProductType.other: LucideIcons.moreHorizontal,
  };

  @override
  Widget build(BuildContext context) {
    final stroke = color ?? context.colors.ink;
    final icon = _icons[type] ?? LucideIcons.moreHorizontal;
    return Icon(icon, size: size, color: stroke);
  }
}
