import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../brand/kolabing_k_mark.dart';
import 'profile_avatar_button.dart';

/// Kolabing standard app bar — yellow background, charcoal text/icons.
class KolabingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KolabingAppBar({super.key, this.showBackButton = false, this.actions});

  final bool showBackButton;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.navBarBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: context.colors.charcoal,
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      // The K, dark on the yellow bar, filling itself once as the screen
      // arrives. It replaces the flat wordmark PNG: same mark as the app icon
      // and the splash, so the brand is one shape everywhere.
      title: AnimatedKolabingKMark(width: 34, color: context.colors.charcoal),
      centerTitle: true,
      // Chat moved to the bottom-nav (NF-12); the avatar opens the now-hidden
      // profile (community/attendee have no Profile tab anymore).
      actions: actions ?? const [ProfileAvatarButton()],
    );
  }
}
