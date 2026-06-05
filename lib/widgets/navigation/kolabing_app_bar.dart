import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';
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
      title: Text(
        'KOLABING',
        style: KolabingTextStyles.headlineMedium.copyWith(
          color: context.colors.charcoal,
          letterSpacing: 2.0,
        ),
      ),
      centerTitle: true,
      // Chat moved to the bottom-nav (NF-12); the avatar opens the now-hidden
      // profile (community/attendee have no Profile tab anymore).
      actions: actions ?? const [ProfileAvatarButton()],
    );
  }
}
