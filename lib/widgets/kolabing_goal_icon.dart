import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/theme/color_tokens.dart';

/// Icon for a Kolab goal, keyed by the admin goal option `slug`.
///
/// Uses the same Lucide icon set as the rest of the app instead of hand-drawn
/// paths, so it renders crisply and consistently at small sizes.
///
/// Matching is case-insensitive and strips non-alphanumeric punctuation, so
/// seed-data variations (`more-visits`, `More Visits`) resolve to the same
/// glyph. Any unmapped slug falls back to the Reviews star — never blank.
class KolabingGoalIcon extends StatelessWidget {
  const KolabingGoalIcon(
    this.goalSlug, {
    super.key,
    this.size = 24,
    this.color,
  });

  final String goalSlug;
  final double size;
  final Color? color;

  static const Map<String, IconData> _icons = {
    'morevisits': LucideIcons.mapPin,
    'productawareness': LucideIcons.megaphone,
    'contenttaggedposts': LucideIcons.camera,
    'reviews': LucideIcons.star,
    'salesrevenue': LucideIcons.trendingUp,
    'producttesting': LucideIcons.flaskConical,
    'communityevent': LucideIcons.calendarHeart,
  };

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final stroke = color ?? context.colors.ink;
    final icon = _icons[_normalize(goalSlug)] ?? LucideIcons.star;
    return Icon(icon, size: size, color: stroke);
  }
}
