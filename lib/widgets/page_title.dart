import 'package:flutter/material.dart';

import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';

/// Reusable main screen title (Explore, Business dashboard, My Kolabs,
/// Profile...). Renders [title] using [KolabingTextStyles.screenTitle] —
/// sentence case, no Anton.
///
/// This is intentionally minimal: it does not lay out trailing actions or
/// avatars, since those differ per screen. Wrap it in the screen's own
/// header row alongside its own trailing widgets.
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: KolabingTextStyles.screenTitle.copyWith(
      color: color ?? context.colors.titleInk,
    ),
  );
}
