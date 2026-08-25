import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

/// The back control on a full-bleed hero.
///
/// `Navigator.maybePop()` is the wrong instrument here and it failed silently:
/// these pages are pushed by go_router and can also be entered **cold from a
/// deep link**, where there is nothing on the navigator to pop and the button
/// simply did nothing. Three fallbacks, in the order they can succeed:
///
/// 1. the ambient navigator, which covers a plain `MaterialPageRoute` push;
/// 2. the router's own stack, for a `context.push` that landed elsewhere;
/// 3. the app's entry point — a deep-linked visitor with no history behind them
///    should be let into the app, not left pressing a dead button.
class HeroBackButton extends StatelessWidget {
  const HeroBackButton({super.key});

  @override
  Widget build(BuildContext context) => HeroCircleAction(
    icon: LucideIcons.arrowLeft,
    onTap: () {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }
      // maybeOf, not of: a hero pumped outside a router (a widget test, a
      // preview) must not crash on its own back button.
      final router = GoRouter.maybeOf(context);
      if (router == null) return;
      if (router.canPop()) {
        router.pop();
        return;
      }
      router.go('/');
    },
  );
}
