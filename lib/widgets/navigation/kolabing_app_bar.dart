import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import 'profile_avatar_button.dart';

/// Kolabing standard app bar — yellow background, charcoal text/icons.
class KolabingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KolabingAppBar({
    super.key,
    this.showBackButton = false,
    this.actions,
  });

  final bool showBackButton;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: KolabingColors.navBarBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              color: KolabingColors.charcoal,
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Image.asset(
        'assets/brand/kolabing-wordmark-dark.png',
        height: 34,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      // Chat moved to the bottom-nav (NF-12); the avatar opens the now-hidden
      // profile (community/attendee have no Profile tab anymore).
      actions: actions ?? const [ProfileAvatarButton()],
    );
  }
}
