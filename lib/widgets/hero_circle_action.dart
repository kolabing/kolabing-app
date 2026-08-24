import 'package:flutter/material.dart';

import '../config/constants/spacing.dart';

/// Translucent circular icon button for use on top of a cover photo or band.
///
/// Shared by the community and event pages: both put their back button and
/// their actions over full-bleed artwork, where a plain `IconButton` disappears
/// against a light photo.
class HeroCircleAction extends StatelessWidget {
  const HeroCircleAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(left: KolabingSpacing.xs),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}
