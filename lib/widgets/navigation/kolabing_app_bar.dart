import 'package:flutter/material.dart';

import '../../config/constants/spacing.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';

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
      title: Text(
        'KOLABING',
        style: KolabingTextStyles.headlineMedium.copyWith(
          color: KolabingColors.charcoal,
          letterSpacing: 2.0,
        ),
      ),
      centerTitle: true,
      actions: actions ??
          [
            Padding(
              padding: const EdgeInsets.only(right: KolabingSpacing.md),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: KolabingColors.charcoal,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: KolabingColors.navBarBackground,
                ),
              ),
            ),
          ],
    );
  }
}
