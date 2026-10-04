import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/colors.dart';
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
      // The K app-icon tile + the brand name: the same mark as the app icon,
      // splash and auth screens (the cloud wordmark is retired, #234).
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/brand/kolabing-app-icon-k.png',
              key: const Key('app-bar-k-mark'),
              width: 30,
              height: 30,
              semanticLabel: 'Kolabing',
            ),
          ),
          const SizedBox(width: 10),
          // Brand name — exempt from i18n.
          Text(
            'KOLABING',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: context.colors.charcoal,
            ),
          ),
        ],
      ),
      centerTitle: true,
      // Chat moved to the bottom-nav (NF-12); the avatar opens the now-hidden
      // profile (community/attendee have no Profile tab anymore).
      actions: actions ?? const [ProfileAvatarButton()],
    );
  }
}
