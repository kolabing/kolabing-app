import 'package:flutter/material.dart';

import '../../config/constants/spacing.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';
import '../../features/notification/widgets/notification_bell.dart';
import 'profile_avatar_button.dart';

/// Shared header for the five main tabs (both roles).
///
/// Renders an uppercase [title] on the left, with a [NotificationBell] and the
/// canonical [ProfileAvatarButton] right-aligned. Background-less and
/// no-elevation so it sits inline at the top of a tab body (the bottom nav and
/// any sub-tab bar render below it). The bell + avatar are always shown.
///
/// This is a plain inline widget (not a [PreferredSizeWidget]); place it as the
/// first child of a tab's body Column. It wraps itself in a top-only [SafeArea]
/// which is idempotent — when the host already provides a SafeArea it adds no
/// extra inset.
class KolabingMainAppBar extends StatelessWidget {
  const KolabingMainAppBar({super.key, required this.title, this.bottom});

  /// Already-localized title. The bar uppercases it.
  final String title;

  /// Optional widget rendered directly below the header row (e.g. a sub-tab
  /// bar). Kept inside the same SafeArea so spacing stays consistent.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KolabingSpacing.md,
              KolabingSpacing.xs,
              KolabingSpacing.md,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: KolabingTextStyles.headlineLarge.copyWith(
                      color: context.colors.titleInk,
                      letterSpacing: 1.0,
                    ),
                    // Keep the title on one line (no 2-row wrap under large fonts).
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const NotificationBell(),
                const SizedBox(width: KolabingSpacing.xs),
                const ProfileAvatarButton(),
              ],
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
